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
    u.counters.find_counter!(ProductCounter, :products)
    assert 1, Counter::Value.count
  end

  test "loads all counters" do
    u = User.create
    u.counters.create! type: ProductCounter, name: :products
    assert User.with_counters.first.counters.loaded?
  end

  test "increments the counter when an item is added" do
    u = User.create
    counter = u.counters.create! type: ProductCounter, name: :products
    u.products.create!
    assert_equal 1, counter.reload.value
  end

  test "decrements the counter when an item is destroy" do
    u = User.create
    product = u.products.create!
    counter = u.counters.find_counter! ProductCounter, :products
    assert_equal 1, counter.reload.value
    product.destroy!
    assert_equal 0, counter.reload.value
  end

  test "does not change the counter when an item is updated" do
    u = User.create!
    counter = u.counters.find_counter! ProductCounter, :products
    product = u.products.create!
    assert_equal 1, counter.reload.value
    product.update! name: "new name"
    assert_equal 1, counter.reload.value
  end
end
