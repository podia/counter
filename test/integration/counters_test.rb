require "test_helper"

class CountersTest < ActiveSupport::TestCase
  test "configures the counters on the parent model" do
    configs = User.counter_configs
    assert_equal 1, configs.length
    config = configs.first
    assert_equal ProductCounter, config.counter_class
    assert_equal User, config.parent_class
    assert_equal :products, config.association
    assert_equal :user, config.inverse_association
  end

  test "configures the counterable" do
    User
    configs = Product.counted_by
    assert_equal 1, configs.length
    config = configs.first
    assert_equal ProductCounter, config.counter_class
    assert_equal User, config.parent_class
    assert_equal :products, config.association
    assert_equal :user, config.inverse_association
  end
end
