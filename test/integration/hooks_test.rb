require "test_helper"

class HooksTest < ActiveSupport::TestCase
  test "allows hooks to be defined on the counter" do
    u = User.create!
    product = u.products.create!
    assert_output "Congratulations! You've made 1000 dollars!\n" do
      u.orders.create! product: product, price: 1000
    end
    product.order_revenue.reset!
    u.orders.create! product: product, price: 500
    assert_output "Congratulations! You've made 1000 dollars!\n" do
      u.orders.create! product: product, price: 500
    end

    assert_output "" do
      u.orders.create! product: product, price: 500
    end
  end
end
