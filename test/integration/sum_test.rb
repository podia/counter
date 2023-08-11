require "test_helper"

class SumTest < ActiveSupport::TestCase
  test "can sum a column value" do
    u = User.create!
    product = u.products.create!
    3.times { u.orders.create! product: product, price: 10 }
    counter = product.order_revenue
    assert_equal 30, counter.value
  end
end
