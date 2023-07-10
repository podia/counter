require "test_helper"

class CountersTest < ActiveSupport::TestCase
  test "configures the counters on the parent model" do
    definitions = User.counter_configs
    assert_equal 1, definitions.length
    definition = definitions.first
    assert_equal ProductCounter, definition
    assert_equal User, definition.model
    assert_equal :products, definition.association_name
    assert_equal :user, definition.inverse_association
  end

  test "configures the counterable" do
    User
    definitions = Product.counted_by
    assert_equal 1, definitions.length
    definition = definitions.first
    assert_equal ProductCounter, definition
    assert_equal User, definition.model
    assert_equal :products, definition.association_name
    assert_equal :user, definition.inverse_association
  end

  # test "finds a counter" do
  #   u = User.create
  #   assert_nil u.counters.find_counter(ProductCounter, :products)
  #   counter = u.counters.create! type: ProductCounter, name: :products
  #   assert_equal counter, u.counters.find_counter(ProductCounter, :products)
  # end

  # test "finds or creates a counter" do
  #   u = User.create
  #   counter = u.counters.find_counter!(ProductCounter, :products)
  #   assert_equal ProductCounter, counter.class
  #   assert_equal "products", counter.name
  #   assert counter.persisted?
  #   assert_equal u, counter.parent
  #   u.counters.find_counter!(ProductCounter, :products)
  #   assert 1, Counter::Value.count
  # end

  # test "loads all counters" do
  #   u = User.create
  #   u.counters.create! type: ProductCounter, name: :products
  #   assert User.with_counters.first.counters.loaded?
  # end

  # test "increments the counter when an item is added" do
  #   u = User.create
  #   counter = u.counters.create! type: ProductCounter, name: :products
  #   u.products.create!
  #   assert_equal 1, counter.reload.value
  # end

  # test "decrements the counter when an item is destroy" do
  #   u = User.create
  #   product = u.products.create!
  #   counter = u.counters.find_counter! ProductCounter, :products
  #   assert_equal 1, counter.reload.value
  #   product.destroy!
  #   assert_equal 0, counter.reload.value
  # end

  # test "does not change the counter when an item is updated" do
  #   u = User.create!
  #   counter = u.counters.find_counter! ProductCounter, :products
  #   product = u.products.create!
  #   assert_equal 1, counter.reload.value
  #   product.update! name: "new name"
  #   assert_equal 1, counter.reload.value
  # end

  # test "resets the counter " do
  #   u = User.create
  #   product = u.products.create!
  #   counter = u.counters.find_counter! ProductCounter, :products
  #   assert_equal 1, counter.reload.value
  #   counter.reset!
  #   assert_equal 0, counter.reload.value
  # end

  # test "an association counter can be recalculated" do
  #   u = User.create!
  #   u.products.create!
  #   counter = u.counters.find_counter! ProductCounter, :products
  #   counter.update! value: 0
  #   counter.recalc!
  #   assert_equal 1, counter.reload.value
  # end

  # test "can sum a column value" do
  #   u = User.create!
  #   product = u.products.create!
  #   3.times { u.orders.create! product: product, price: 10 }
  #   counter = u.counters.find_counter! Counter::Value, :orders
  #   assert_equal 30, counter.value
  # end

  # test "can recalculate a sum" do
  #   u = User.create!
  #   product = u.products.create!
  #   3.times { u.orders.create! product: product, price: 10 }
  #   counter = u.counters.find_counter! Counter::Value, :orders
  #   counter.reset!
  #   assert_equal 0, counter.value
  #   counter.recalc!
  #   assert_equal 30, counter.value
  # end

  # test "included the Counter::Changed module only when filters are passed"
  # test "passing filters to the keep_count_of"
  # test "accept_item? with symbol"
  # test "accept_item? with proc"
end
