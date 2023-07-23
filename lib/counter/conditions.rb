class Counter::Conditions
  attr_accessor :increment_conditions, :decrement_conditions

  def initialize
    @increment_conditions = []
    @decrement_conditions = []
  end

  def increment_if block
    increment_conditions << block
  end

  def decrement_if block
    decrement_conditions << block
  end
end
