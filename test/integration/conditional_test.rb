require "test_helper"

class ConditionalTest < ActiveSupport::TestCase
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
  end

  test "conditionally decrements the counter when deleting" do
    u = User.create!
    product = Product.create! user: u, price: 1000
    assert_equal 1, u.premium_products_counter.value
    product.destroy
    assert_equal 0, u.premium_products_counter.value
  end
end
