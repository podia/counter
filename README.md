# Counter
High performance counting library for Rails.

- Counters are first class objects. They are persisted as an ActiveRecord model (_not_ a column)
- Incrementing counters is performed in a background job
- Avoids lock-contention found in other solutions
- In addition to counting (e.g. the number of orders), it can also maintain a running total (e.g. revenue)

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
