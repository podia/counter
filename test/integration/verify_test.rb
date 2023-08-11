require "test_helper"

class VerifyTest < ActiveSupport::TestCase
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
end
