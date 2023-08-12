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

  test "verifies a calculated counter" do
    u = User.create
    u.orders_counter.increment! by: 2
    u.visits_counter.increment! by: 100
    u.conversion_rate.update! value: 0.5
    assert !u.conversion_rate.correct?
  end

  test "verify return correct and current values" do
    u = User.create
    u.products.create!
    u.products_counter.increment! by: 2
    assert [1, 3], u.products_counter.verify
  end

  test "sample_and_verify" do
    u = User.create!
    u.products.create!
    u.products_counter.increment! by: 2
    assert_equal 1, Counter::Value.sample_and_verify(samples: 1, verbose: false, on_error: :correct)
  end
end
