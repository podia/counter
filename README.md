# Counter
High performance counting library for Rails.

- Counters are first class objects. They are persisted as an ActiveRecord model (_not_ a column)
- Incrementing counters is performed in a background job
- Avoids lock-contention found in other solutions
- In addition to counting (e.g. the number of orders), it can also maintain a running total (e.g. revenue)

## Main concepts

`Counter::Definition` defines what the counter is, what model it's connected to, what association it counts, how the count is performed etc. This is available through `counter.definition`

`Counter::Value` is the value of a counter. So, for example, a User might have many Posts, so a User would have a `counters` association containing a `Counter::Value` for the number of posts.

`Counter::Change` is a temporary record that records a change to a counter. Instead of updating a counter directly, which requires obtaining a lock on it to perform it atomically, a new `Change` event is inserted into the table. On regular intervals, the `Counter::Value` is updated by incrementing the value by the sum of all outstanding changes. This requires much less frequent locks at the expense of eventual consistency.

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

Todo:
- How define a counter
- How to define conditional counters
- How to define summable counters (e.g. revenue)
- How to recalculate a counter
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
