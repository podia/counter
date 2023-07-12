# Counter
Counting and aggregation library for Rails.

By the time you need Rails counter_caches you probably have other needs too. You probably want to sum column values and you probably have enough throughput that updating a single column value will cause lock contention problems too.

Counter is different from other solutions like Rails counter caches and counter_culture:

- Counters are objects. This makes it possible for them to have an API that allows you to define them, reset, and recalculate them
- Counters are persisted as an ActiveRecord model (_not_ a column)
- Incrementing counters can be safely performed in a background job via a change event/deferred reconciliation pattern
- Avoids lock-contention found in other solutions. Firstly, by storing the value in another object we reduce the contention on the main e.g. User instance. By using the change event pattern, we batch perform the updates reducing the number of processes requiring a lock.
- Counters can also perform aggregation (e.g. sum of column values instead of counting rows)

- [Counter](#counter)
  - [Main concepts](#main-concepts)
  - [Defining a conditional counter](#defining-a-conditional-counter)
  - [Defining a counter that aggregates a value (e.g. sum of order revenue)](#defining-a-counter-that-aggregates-a-value-eg-sum-of-order-revenue)
  - [Recalculating a counter](#recalculating-a-counter)
  - [Reset a counter](#reset-a-counter)
  - [Usage](#usage)
  - [Installation](#installation)
  - [Contributing](#contributing)
  - [License](#license)


## Main concepts

`Counter::Definition` defines what the counter is, what model it's connected to, what association it counts, how the count is performed etc. You create a subclass of `Counter::Definition` and call a few class methods to configure it. The definition is available through `counter.definition` for any counter value…

`Counter::Value` is the value of a counter. So, for example, a User might have many Posts, so a User would have a `counters` association containing a `Counter::Value` for the number of posts. Counters can be accessed via their name `user.posts_counter` or via the counters method on the association `user.counters.find_counter PostCounter`

`Counter::Change` is a temporary record that records a change to a counter. Instead of updating a counter directly, which requires obtaining a lock on it to perform it safely and atomically, a new `Change` event is inserted into the table. On regular intervals, the `Counter::Value` is updated by incrementing the value by the sum of all outstanding changes. This requires much less frequent locks at the expense of eventual consistency.

For example, you might have many background jobs running concurrently, inserting hundreds/thousands of rows. The would not need to fight for a lock to update the counter and would only need to insert Counter::Change rows. The counter would then be updated, in a single operation, by summing all the persisted change values.

Basically updating a counter value requires this SQL:

```sql
UPDATE counter_values
-- Update the counter with the sum of pending changes
SET value = value + changes.sum
FROM (
  -- Find the pending changes for the counter
  SELECT sum(value) as sum
  FROM counter_changes
  WHERE counter_id = 100
) as changes
WHERE id = 100
```

Or even reconcile all pending counters in a single statement:

```sql
UPDATE counter_values
SET value = value + changes.sum
FROM (
  SELECT sum(value)
  FROM counter_changes
  GROUP BY counter_id
) as changes
WHERE counters.id = counter_id
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
class PremiumProductCounter
  include Counter::Definition

  count :premium_products
  conditional create: ->(product) { product.premium? },
    update: ->(product) {
      product.has_changed? :price,
        from: ->(price) { price < 1000 },
        to: ->(price) { price >= 1000 }
    },
    delete: ->(product) { product.premium? }
end
```

What's to note here? First, we define the counter on a scoped association. This ensures that when we call `counter.recalc()` we will count the association. We also define filters that operate on the instance level. On `create` we only accept premium products. On `delete` we only accept premium products. On `update`, we only accept products that have changed from < 1000 to a price >= 1000.

## Defining a counter that aggregates a value (e.g. sum of order revenue)

Given an ActiveRecord model `Order`, we can count a storefront's revenue like so

```ruby
class Store < ApplicationRecord
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

## Recalculating a counter

Counters have a habit of drifting over time, particularly if ActiveRecords hooks are run (e.g. with a pure SQL data migration) so you need a method of re-counting the metric. Counters make this easy because they are objects in their own right.

You could refresh a store's revenue stats with:

```ruby
store.order_revenue.recalc!
```

this would use the definition of the counter, including any option to sum a column. In the case of conditional counters, they are expect to be attached to an association which match the conditions.

## Reset a counter

You can also reset a counter by calling `reset`. Since counters are ActiveRecord objects, you could also reset them using

```ruby
Counter::Value.update value: 0
```

Todo:
- How define a counter
- How to reset a counter
- Rethink? How to define hierarchical counters. Just add Change records for each of them? Or are rollups a different concept?
- Not implemented: How define time-based counters for analytics
- Can we support floating point values?
- Can we support other aggregations such as average? Would require storing a list of recent items. Or HLL?
## Usage
You probably shouldn't right now unless you're the sort of person that checks if something is poisonous by licking it

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'counter'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install counter
```

Install the model migrations:
```bash
$ rails counter:install:migrations
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
