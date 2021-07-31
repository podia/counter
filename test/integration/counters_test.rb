require "test_helper"

class CountersTest < ActiveSupport::TestCase
  test "configures the counters on the parent model" do
    configs = User.counter_configs
    assert_equal 1, configs.length
    config = configs.first
    assert_equal ProductCounter, config.counter_class
    assert_equal User, config.parent_class
    assert_equal :products, config.association
    assert_equal :user, config.inverse_association
  end

  test "configures the counterable" do
    User
    configs = Product.counted_by
    assert_equal 1, configs.length
    config = configs.first
    assert_equal ProductCounter, config.counter_class
    assert_equal User, config.parent_class
    assert_equal :products, config.association
    assert_equal :user, config.inverse_association
  end

  test "finds a counter" do
    u = User.create
    assert_nil u.counters.find_counter(ProductCounter, :products)
    counter = u.counters.create! type: ProductCounter, name: :products
    assert_equal counter, u.counters.find_counter(ProductCounter, :products)
  end

  test "finds or creates a counter" do
    u = User.create
    counter = u.counters.find_counter!(ProductCounter, :products)
    assert_equal ProductCounter, counter.class
    assert_equal "products", counter.name
    assert counter.persisted?
    assert_equal u, counter.parent
  end

  test "loads all counters" do
    u = User.create
    u.counters.create! type: ProductCounter, name: :products
    assert User.with_counters.first.counters.loaded?
  end
end
