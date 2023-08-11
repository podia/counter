require "test_helper"

class ResetTest < ActiveSupport::TestCase
  test "resets the counter " do
    u = User.create
    u.products.create!
    counter = u.counters.find_counter ProductCounter
    assert_equal 1, counter.reload.value
    counter.reset!
    assert_equal 0, counter.reload.value
  end
end
