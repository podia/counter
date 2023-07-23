require "test_helper"

class CountersTest < ActiveSupport::TestCase
  test "configures the counters on the parent model" do
    definitions = User.counter_configs
    assert_equal 2, definitions.length
    definition = definitions.first
    assert_equal ProductCounter, definition.class
    assert_equal User, definition.model
    assert_equal :products, definition.association_name
    assert_equal :user, definition.inverse_association
  end

  test "configures the thing being counted" do
    definitions = Product.counted_by
    assert_equal 2, definitions.length
    definition = definitions.first
    assert_kind_of ProductCounter, definition
    assert_equal User, definition.model
    assert_equal :products, definition.association_name
    assert_equal :user, definition.inverse_association
  end

  test "find a counter by calling method name" do
    u = User.create!
    u.counters.create! name: "user-products"
    assert_equal Counter::Value, u.products_counter.class
    assert_kind_of ProductCounter, u.products_counter.definition
  end

  test "counter has a definition" do
    u = User.create!
    counter = u.counters.create! name: "user-products"
    assert_kind_of ProductCounter, counter.definition
  end

  test "finds a counter" do
    u = User.create!
    assert_nil u.counters.find_counter(ProductCounter)
    assert_nil u.counters.find_counter("user-products")
    counter = u.counters.create! name: "user-products"
    assert_equal counter, u.counters.find_counter("user-products")
    assert_equal counter, u.counters.find_counter(ProductCounter)
  end

  test "adds a method for the counter" do
    u = User.create!
    counter = u.premium_products_counter
    assert_equal 0, counter.value
    assert_equal Counter::Value, counter.class
    assert_equal "user-premium_products", counter.name
    assert_kind_of PremiumProductCounter, counter.definition
  end

  test "allows counters to configure the counter name" do
    u = User.create!
    product = Product.create! user: u
    assert_equal "order_revenue", product.order_revenue.definition.name
  end

  test "finds or creates a counter" do
    u = User.create!
    counter = u.counters.find_or_create_counter!(ProductCounter)
    assert_equal Counter::Value, counter.class
    assert_equal "user-products", counter.name
    assert counter.new_record?
    assert_equal u, counter.parent
    u.counters.find_counter(ProductCounter)
    assert 1, Counter::Value.count
  end

  test "loads all counters" do
    u = User.create
    u.counters.create! name: "user-products"
    assert User.with_counters.first.counters.loaded?
  end

  test "do not blow up if a counter hasn't been created" do
    u = User.create
    # No counter for products has been created but this should
    # still work and return a new instance
    assert u.products_counter.new_record?
  end

  test "define a global counter" do
    definition = GlobalOrderCounter.instance
    assert definition.global?
    assert_equal "total_orders", definition.name
    assert_kind_of Counter::Value, GlobalOrderCounter.counter
    GlobalOrderCounter.counter.increment!
    assert 1, GlobalOrderCounter.counter.value
    assert GlobalOrderCounter.instance, GlobalOrderCounter.counter.definition
  end

  test "increments the counter when an item is added" do
    u = User.create
    u.products.create!
    counter = u.counters.find_or_create_counter! ProductCounter
    assert_equal 1, counter.value
  end

  test "decrements the counter when an item is destroy" do
    u = User.create
    product = u.products.create!
    counter = u.counters.find_or_create_counter! ProductCounter
    assert_equal 1, counter.value
    product.destroy!
    assert_equal 0, counter.reload.value
  end

  test "does not change the counter when an item is updated" do
    u = User.create!
    product = u.products.create!
    counter = u.counters.find_counter ProductCounter
    assert_equal 1, counter.reload.value
    product.update! name: "new name"
    assert_equal 1, counter.reload.value
  end

  test "verifies if the counter is correct" do
    u = User.create
    u.products.create!
    counter = u.products_counter
    assert_equal 1, counter.reload.value
    assert counter.correct?
    assert_equal true, counter.correct!
    counter.reset!
    assert !counter.correct?
    assert_equal false, counter.correct!
    assert 1, counter.value
  end

  test "resets the counter " do
    u = User.create
    u.products.create!
    counter = u.counters.find_counter ProductCounter
    assert_equal 1, counter.reload.value
    counter.reset!
    assert_equal 0, counter.reload.value
  end

  test "an association counter can be recalculated" do
    u = User.create!
    u.products.create! price: 1000
    u.products.create! price: 10
    counter = u.premium_products_counter
    counter.update! value: 0
    counter.recalc!
    assert_equal 1, counter.reload.value
  end

  test "can sum a column value" do
    u = User.create!
    product = u.products.create!
    3.times { u.orders.create! product: product, price: 10 }
    counter = product.order_revenue
    assert_equal 30, counter.value
  end

  test "can recalculate a sum" do
    u = User.create!
    product = u.products.create!
    3.times { u.orders.create! product: product, price: 10 }
    counter = product.order_revenue
    counter.reset!
    assert_equal 0, counter.value
    counter.recalc!
    assert_equal 30, counter.value
  end

  test "conditionally increments the counter" do
    u = User.create!
    Product.create! user: u, price: 100
    assert_equal 0, u.premium_products_counter.value
    product = Product.create! user: u, price: 1000
    assert_equal 1, u.premium_products_counter.value
    product.update! price: 1001
    assert_equal 1, u.premium_products_counter.value
    product.destroy
    assert_equal 0, u.premium_products_counter.value
  end

  test "conditionally decrements the counter when updating" do
    u = User.create!
    product = Product.create! user: u, price: 1000
    assert_equal 1, u.premium_products_counter.value
    product.update! price: 100
    assert_equal 0, u.premium_products_counter.value
    product.destroy
    assert_equal 0, u.premium_products_counter.value
  end
end
