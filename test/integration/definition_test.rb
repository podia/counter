require "test_helper"

class DefinitionTest < ActiveSupport::TestCase
  test "configures the counters on the parent model" do
    definitions = User.counter_configs
    assert_equal 7, definitions.length
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

  test "counters can just be their own thing, not associated with an association" do
    u = User.create!
    visits_counter = u.visits_counter
    assert_kind_of Counter::Value, visits_counter
    visits_counter.increment! by: 10
    assert 10, visits_counter.value
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

  test "sets the counter name" do
    assert_equal "visits_counter", VisitsCounter.instance.name
  end

  test "preloads the counters" do
    u = User.create!
    u.products.create!
    u.products.create! price: 1000

    assert User.with_counters.first.association(:counters).loaded?
  end

  test "loads the counter data" do
    u = User.create!
    2.times { u.products.create! }
    u.products.create! price: 1000
    u = User.with_counter_data_from(ProductCounter, PremiumProductCounter).first

    assert_equal 3, u.products_counter_data
    assert_equal 1, u.premium_products_counter_data
  end

  test "orders the results by the counter data" do
    u1 = User.create!
    2.times { u1.products.create! }
    u2 = User.create!
    5.times { u2.products.create! }
    results = User.order_by_counter(ProductCounter => :desc)
    assert_equal [u2, u1], results
  end

  test "order is chainable" do
    u1 = User.create!
    2.times { u1.products.create! }
    u2 = User.create!
    5.times { u2.products.create! }
    results = User.order_by_counter(ProductCounter => :desc).where(id: u1.id).pluck :id
    assert_equal [u1.id], results
    results = User.where(id: u1.id).order_by_counter(ProductCounter => :desc)
    assert_equal [u1], results
  end

  test "orders the results with mixed counter data and attributes" do
    u1 = User.create!
    2.times { u1.products.create! }
    u2 = User.create!
    2.times { u2.products.create! }
    results = User.order_by_counter(ProductCounter => :desc, :id => :asc)
    assert_equal [u1, u2], results
  end

  test "manual counters aren't calculated" do
    u = User.create!
    # Calculated counter are not manual
    assert_equal false, u.conversion_rate.definition.manual?
    # Counters without associations are manual
    assert_equal true, u.visits_counter.definition.manual?
    # Global counters are manual
    assert_equal true, GlobalOrderCounter.counter.definition.manual?
  end

  test "subclasses should inherit counters from superclasses" do
    u = User.create!
    product = SpecialProduct.create! user: u, price: 10
    product.orders.create! price: 10, user: u
    assert_kind_of Counter::Value, product.order_revenue
    assert 10, product.order_revenue.value
  end

  test "calculated values can be defined" do
    assert_kind_of Proc, CigaretteCounter.instance.calculated_value
  end

  test "calculated values can define an association" do
    assert_kind_of Proc, ReturnedOrderCounter.instance.calculated_value
    assert_equal :orders, ReturnedOrderCounter.instance.association_name
  end

  test "calculated values set a default name" do
    assert_equal "cigarette_counter", CigaretteCounter.instance.name
    assert_equal "cigarette_counter", CigaretteCounter.instance.method_name
  end

  test "value record names can be defined" do
    assert_equal "users_returned_orders", ReturnedOrderCounter.instance.record_name
  end
end
