require "test_helper"

class CountersControllerTest < ActionDispatch::IntegrationTest
  test "should be reset" do
    counter = Counter::Value.create! value: 50
    delete counter_path(counter)
    assert_response :redirect
    assert_equal(0, counter.reload.value)
  end

  test "should be recalculated" do
    counter = Counter::Value.create! value: 50
    patch counter_path(counter)
    assert_response :redirect
    assert_equal(0, counter.reload.value)
  end
end
