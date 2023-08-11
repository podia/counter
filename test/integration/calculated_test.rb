require "test_helper"

class CalculatedTest < ActiveSupport::TestCase
  test "calculated counters are kept up-to-date" do
    u = User.create!
    product = Product.create! user: u, price: 1000
    u.visits_counter.increment! by: 100
    2.times { u.orders.create! product: product, price: 100 }
    assert_equal 2, u.conversion_rate.value
  end
end
