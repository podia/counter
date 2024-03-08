require "test_helper"

class RecalcTest < ActiveSupport::TestCase
  test "an association counter can be recalculated" do
    u = User.create!
    u.products.create! price: 1000
    u.products.create! price: 10
    counter = u.premium_products_counter
    counter.update! value: 0
    counter.recalc!
    assert_equal 1, counter.reload.value
  end

  test "a manual counter can't be recalculated" do
    u = User.create!
    assert_raise Counter::Error do
      u.visits_counter.recalc!
    end
  end

  test "can recalculate a sum" do
    u = User.create!
    product = u.products.create!
    3.times { u.orders.create! product: product, price: 10 }
    counter = product.order_revenue
    counter.reset!
    assert_equal 0, counter.value
    counter.recalc!
    assert_equal 30, counter.reload.value
  end

  test "can recalculate a calculated counter" do
    u = User.create!
    u.visits_counter.increment! by: 100
    u.orders_counter.increment! by: 2
    u.conversion_rate.reset!
    u.conversion_rate.recalc!
    assert_equal 2, u.conversion_rate.value
  end
end
