require "test_helper"

class ChangesTest < ActiveSupport::TestCase
  test "no changes" do
    user = User.create!
    product = Product.create! user: user, price: 1000
    product = product.reload
    assert !product.has_changed?(:price)
    assert !product.has_changed?(:price, from: 1000)
    assert !product.has_changed?(:price, to: 1000)
    product.update! price: 1001
    assert !product.has_changed?(:price, to: ->(price) { price < 1000 })
    assert !product.has_changed?(:price, from: ->(price) { price > 1000 })
  end

  test "changed from ANY to ANY" do
    user = User.create!
    product = Product.create! user: user, price: 1000
    product.update! price: 2000
    assert product.has_changed?(:price)
  end

  test "changed from ANY implicit to value" do
    user = User.create!
    product = Product.create! user: user, price: 1000
    product.update! price: 2000
    assert product.has_changed?(:price, to: 2000)
  end

  test "changed from ANY to value" do
    user = User.create!
    product = Product.create! user: user, price: 1000
    product.update! price: 2000
    assert product.has_changed?(:price, from: Counter::Any, to: 2000)
  end

  test "changed from value to ANY" do
    user = User.create!
    product = Product.create! user: user, price: 1000
    product.update! price: 2000
    assert product.has_changed?(:price, from: 1000)
  end

  test "changed from block to ANY" do
    user = User.create!
    product = Product.create! user: user, price: 1000
    product.update! price: 2000
    assert product.has_changed?(:price, from: ->(p) { p < 2000 })
  end

  test "changed from ANY to block" do
    user = User.create!
    product = Product.create! user: user, price: 1000
    product.update! price: 2000
    assert product.has_changed?(:price, to: ->(p) { p > 1000 })
  end

  test "changed from block to block" do
    user = User.create!
    product = Product.create! user: user, price: 1000
    product.update! price: 2000
    assert product.has_changed?(:price,
      from: ->(p) { p < 2000 },
      to: ->(p) { p > 1000 })
  end

  test "unchanged from block to block" do
    user = User.create!
    product = Product.create! user: user, price: 2000
    product.update! price: 1000
    assert !product.has_changed?(:price,
      from: ->(p) { p < 2000 },
      to: ->(p) { p > 1000 })
  end

  test "unchanged from value to value" do
    user = User.create!
    product = Product.create! user: user, price: 1000
    product.update! price: 1000
    assert !product.has_changed?(:price, from: 1000)
    assert !product.has_changed?(:price, to: 1000)
  end
end
