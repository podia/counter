# Counter

[![Tests](https://github.com/podia/counter/actions/workflows/ruby.yml/badge.svg)](https://github.com/podia/counter/actions/workflows/ruby.yml)

Counting and aggregation library for Rails.

- [Counter](#counter)
  - [Main concepts](#main-concepts)
  - [Defining a counter](#defining-a-counter)
  - [Accessing counter values](#accessing-counter-values)
  - [Sorting or filter parent models by a counter value](#sorting-or-filter-parent-models-by-a-counter-value)
  - [Global counters](#global-counters)
  - [Defining a conditional counter](#defining-a-conditional-counter)
  - [Aggregating a value (e.g. sum of order revenue)](#aggregating-a-value-eg-sum-of-order-revenue)
  - [Calculating a value from other counters](#calculating-a-value-from-other-counters)
  - [Recalculating a counter](#recalculating-a-counter)
  - [Reset a counter](#reset-a-counter)
  - [Verify a counter](#verify-a-counter)
  - [Hooks](#hooks)
  - [Testing](#testing)
  - [Testing the counters in production](#testing-the-counters-in-production)
  - [TODO](#todo)
  - [Usage](#usage)
  - [Installation](#installation)
  - [Contributing](#contributing)
  - [License](#license)

By the time you need Rails counter_caches you probably have other needs too. You probably want to sum column values and you probably have enough throughput that updating a single column value will cause lock contention problems too.

Counter is different from other solutions like [Rails counter caches](https://api.rubyonrails.org/classes/ActiveRecord/CounterCache/ClassMethods.html) and [counter_culture](https://github.com/magnusvk/counter_culture):

- Counters are objects. This makes it possible for them to have an API that allows you to define them, reset, and recalculate them. The definition of a counter is seperate from the value
- Counters are persisted as a ActiveRecord models (_not_ a column of an existing model)
- Incrementing counters can be safely performed in a background job via a change event/deferred reconciliation pattern
- Avoids lock-contention found in other solutions. By storing the value in another object we reduce the contention on the main e.g. User instance. This is only a small improvement though. By using the background change event pattern, we can batch perform the updates reducing the number of processes requiring a lock.
- Counters can also perform aggregation (e.g. sum of column values instead of counting rows)

## Main concepts

![](docs/data_model.png)

`Counter::Definition` defines what the counter is, what model it's connected to, what association it counts, how the count is performed etc. You create a subclass of `Counter::Definition` and call a few class methods to configure it. The definition is available through `counter.definition` for any counter value…

`Counter::Value` is the value of a counter. So, for example, a User might have many Posts, so a User would have a `counters` association containing a `Counter::Value` for the number of posts. Counters can be accessed via their name `user.posts_counter` or via the `find_counter` method on the association, e.g. `user.counters.find_counter PostCounter`

## Defining a counter

Counters are defined in a seperate class using a small DSL.

Given a `Store` with many `Order`s, it would be defined as…

```ruby
class OrderCounter < Counter::Definition
  count :orders
end

class Store < ApplicationRecord
  include Counter::Counters

  has_many :orders
  counter OrderCounter
end
```

First we define the counter class itself using `count` to specify the association we're counting, then "attach" it to the parent Store model.

By default, the counter will be available as `<association>_counter`, e.g. `store.orders_counter`. To customise this, use the `as` method:

```ruby
class OrderCounter < Counter::Definition
  include Counter::Counters
  count :orders
  as :total_orders
end

store.total_orders
```

The counter's value with be stored as a `Counter::Value` with the name prefixed by the model name. e.g. `store-total_orders`

## Accessing counter values

Since counters are represented as objects, you need to call `value` on them to retrieve the count.

```ruby
store.total_orders        #=> Counter::Value
store.total_orders.value  #=> 200
```

## Sorting or filter parent models by a counter value

Say a Customer has a "total revenue" counter, and you'd like to sort the list of customers with the highest spenders at the top. Since the counts aren't stored on the Customer model, you can't just call `Customer.order(total_orders: :desc)`. Instead, Counterwise provides a convenience method to pull the counter values into the resultset.

```ruby
Customer.order_by_counter TotalRevenueCounter => :desc

# You can sort by multiple counters or mix counters and model attributes
Customer.order_by_counter TotalRevenueCounter => :desc, name: :asc
```

Under the hood, `order_by_counter` will uses `with_counter_data_from` to pull the counter values into the resultset. This is useful if you want to use the counter values in a `where` clause or `select` statement.

```ruby
Customer.with_counter_data_from(TotalRevenueCounter).where("total_revenue_data > 1000")
```

Whilst these methods pulls in th counter values, it doesn't include the counter instances themselves. To do this, call

```ruby
customers = Customer.with_counters TotalRevenueCounter
# Since the counters are now preloaded, this won't hit the database again and avoids an N+1 query
customers.each &:total_revenue
```

## Global counters

Most counters are associated with a model instance and association. These counters are automatically incremented when the associated collection changes but sometimes you just need a global counter that you can increment.

```ruby
class GlobalOrderCounter < Counter::Definition
  global
end

GlobalOrderCounter.counter.value #=> 5
GlobalOrderCounter.counter.increment! #=> 6
```

## Defining a conditional counter

Consider this model that we'd like to count but we don't want to count all products, just the premium ones with a price >= 1000

```ruby
class Product < ApplicationRecord
  include Counter::Counters
  include Counter::Changable

  belongs_to :user

  scope :premium, -> { where("price >= 1000") }

  def premium?
    price >= 1000
  end
end
```

Here's the counter to do that:

```ruby
class PremiumProductCounter < Counter::Definition
  # Define the association we're counting
  count :premium_products

  on :create do
    increment_if ->(product) { product.premium? }
  end

  on :delete do
    decrement_if ->(product) { product.premium? }
  end

  on :update do
    increment_if ->(product) {
      product.has_changed? :price, from: ->(price) { price < 1000 }, to: ->(price) { price >= 1000 }
    }

    decrement_if ->(product) {
      product.has_changed? :price, from: ->(price) { price >= 1000 }, to: ->(price) { price < 1000 }
    }
  end
end
```

There is a lot going on here!

First, we define the counter on a scoped association. This ensures that when we call `counter.recalc()` we will count using the association's SQL.

We also define several conditions that operate on the instance level, i.e. when we create/update/delete an instance. On `create` and `delete` we define a block to determine if the counter should be updated. In this case, we only increment the counter when a premium product is created, and only decrement it when a premium product is deleted.

`update` is more complex because there are two scenarios: either a product has been updated to make it premium or downgrade from premium to some other state. On update, we increment the counter if the price has gone above 1000; and decrement is the price has now gone below 1000.

We use the `has_changed?` helper to query the ActiveRecord `previous_changes` hash and check what has changed. You can specify either Procs or values for `from`/`to`. If you only specify a `from` value, `to` will default to "any value" (Counter::Any.instance)

Conditional counters work best with a single attribute. If the counter is conditional on e.g. confirmed and subscribed, the update tracking logic becomes very complex especially if the values are both updated at the same time. The solution to this is hopefully Rails generated columns in 7.1 so you can store a "subscribed_and_confirmed" column and check the value of that instead. Rails dirty tracking will need to work with generated columns though; see [this PR](https://github.com/rails/rails/pull/48628).

## Aggregating a value (e.g. sum of order revenue)

Given an ActiveRecord model `Order`, we can count a storefront's revenue like so

```ruby
class Store < ApplicationRecord
  include Counter::Counters

  counter OrderRevenue
end
```

Define the counter like so

```ruby
class OrderRevenue < Counter::Definition
  count :orders
  sum :total_price
end
```

and access it like

```ruby
  store.orders.create total_price: 100
  store.orders.create total_price: 100
  store.order_revenue.value #=> 200
```

## Calculating a value from other counters

You may also need have a common need to calculate a value from other counters. For example, given counters for the number of purchases and the number of visits, you might want to calculate the conversion rate. You can do this with a `calculate_from` block.

```ruby
class ConversionRateCounter < Counter::Definition
  count nil, as: "conversion_rate"

  calculated_from VisitsCounter, OrdersCounter do |visits, orders|
    (orders.value.to_f / visits.value) * 100
  end
end
```

This recalculates the conversion rate each time the visits or order counters are updated. If either dependant counter is not present, the calculation will not be run (i.e., visits and order will never be nil).

## Recalculating a counter

Counters have a habit of drifting over time, particularly if ActiveRecords hooks aren't run (e.g. with a pure SQL data migration) so you need a method of re-counting the metric. Counters make this easy because they are objects in their own right.

You could refresh a store's revenue stats with:

```ruby
store.order_revenue.recalc!
```

this would use the definition of the counter, including any option to sum a column. In the case of conditional counters, they are expected to be attached to an association which matched the conditions so the recalculated count remains accurate.

## Reset a counter

You can also reset a counter by calling `reset`. Since counters are ActiveRecord objects, you could also reset them using

```ruby
store.order_revenue.reset
Counter::Value.update value: 0
```

## Verify a counter

You might like to check if a counter is correct

```ruby
store.product_revenue.correct? #=> false
```

This will re-count / re-calculate the value and compare it to the current one. If you wish to also update the value when it's not correct, use `correct!`:

```ruby
store.product_revenue #=>200
store.product_revenue.reset!
store.product_revenue #=>0
store.product_revenue.correct? #=> false
store.product_revenue.correct! #=> false
store.product_revenue #=>200
```

## Hooks

You can add an `after_change` hook to your counter definition to perform some action when the counter is updated. For example, you might want to send a notification when a counter reaches a certain value.

```ruby
class OrderRevenueCounter < Counter::Definition
  count :orders, as: :order_revenue
  sum :price

  after_change :send_congratulations_email

  def send_congratulations_email counter, from, to
    return unless from < 1000 && to >= 1000
    send_email "Congratulations! You've made #{to} dollars!"
  end
end
```

## Testing

If you use RSpec, you can include `Counter::RSpecMatchers` on your helpers and test your counter definitions.

### Include `Counter::RSpecMatchers`

```ruby
require "counter/rspec/matchers"

RSpec.configure do |config|
  config.include Counter::RSpecMatchers, type: :counter
end
```

### Test the counter definition

```ruby
require "rails_helper"

RSpec.describe PremiumProductCounter, type: :counter do
  let(:store) { create(:store) }

  describe "on :create" do
    context "when the product is premium" do
      it "increments the counter" do
        expect { create(:product, :premium, store: store) }.to increment_counter_for(described_class, store)
      end
    end

    context "when the product is not premium" do
      it "doesn't increment the counter" do
        expect { create(:product, store: store) }.not_to increment_counter_for(described_class, store)
      end
    end
  end

  describe "on :delete" do
    context "when the product is premium" do
      it "decrements the counter" do
        expect { create(:product, :premium, store: store) }.to decrement_counter_for(described_class, store)
      end
    end

    context "when the product is not premium" do
      it "doesn't decrement the counter" do
        expect { create(:product, store: store) }.not_to decrement_counter_for(described_class, store)
      end
    end
  end
end
```

## Testing the counters in production

It may be useful to verify the accuracy of the counters in production, especially if you are concerned about conditional counters etc causing counter drift over time.

This form of script takes a sampling approach suitable for large collections. It will randomly select a record and verify that the counter value is correct; if it's not, it stops giving you a chance to investigate.

```ruby
site_range = Site.minimum(:id)..Site.maximum(:id)

1000.times do
  random_id = rand(site_range)
  site = Site.where("id >= ?", random_id).limit(1).first
  next if site.nil?
  if site.confirmed_subscribers_counter.correct?
    puts "✅ site #{site.id} has correct counter value"
  else
    puts "❌ site #{site.id} has incorrect counter value. Expected #{site.confirmed_subscribers_counter.value} but got #{site.confirmed_subscribers_counter.count_by_sql}"
    break
  end
  sleep 0.1
end
```

---

## TODO

See the asociated project in Github but roughly I'm thinking:
- Implement the background job pattern for incrementing counters
- Hierarchical counters. For example, a Site sends many Newsletters and each Newsletter results in many EmailMessages. Each EmailMessage can be marked as spam. How do you create counters for how many spam emails were sent at the Newsletter level and the Site level?
- Time-based counters for analytics. Instead of a User having one OrderRevenue counter, they would have an OrderRevenue counter for each day. These counters would then be used to produce a chart of their product revenue over the month. Not sure if these are just special counters or something else entirely? Do they use the same ActiveRecord model?
- In a similar vein of supporting different value types, can we support HLL values? Instead of increment an integer we add the items hash to a HyperLogLog so we can count unique items. An example would be counting site visits in a time-based daily counter, then combine the daily counts and still obtain an estimated number of monthly _unique_ visits. Again, not sure if this is the same ActiveRecord model or something different.
- Actually start running this in production for basic use cases

## Usage

No one has used this in production yet.

You probably shouldn't right now unless you're the sort of person that checks if something is poisonous by licking it.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'counter'
```

And then execute:

```bash
$ bundle
```

Install the model migrations:

```bash
$ rails counter:install:migrations
```

## Contributing

Contribution directions go here.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
