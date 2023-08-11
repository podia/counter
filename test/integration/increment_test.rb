require "test_helper"

class CountersTest < ActiveSupport::TestCase
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

  test "decrements the counter when an newly-loaded item is destroy" do
    u = User.create
    product = u.products.create!
    # Reloading the product means the user association is no longer loaded
    product.reload
    product.destroy!
    assert_equal 0, u.products_counter.reload.value
  end

  test "does not change the counter when an item is updated" do
    u = User.create!
    product = u.products.create!
    counter = u.counters.find_counter ProductCounter
    assert_equal 1, counter.reload.value
    product.update! name: "new name"
    assert_equal 1, counter.reload.value
  end
end
