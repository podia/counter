module Counter::Changed
  extend ActiveSupport::Concern

  included do
    def has_changed? attribute, from: Any.new, to: Any.new
      old_value, new_value = previous_changes[attribute]

      # Return false if nothing changed
      return false if old_value == new_value

      # Return true if the attribute changed at all
      return true if from.instance_of?(Any) && to.instance_of?(Any)

      # Check if the value change from <something>
      return new_value == to if from.instance_of?(Any)
      # Check if the value change to <something>
      return old_value == from if to.instance_of?(Any)

      # Check if the value change from <something> to <something>
      old_value == from && new_value == to
    end
  end

  class Any
    include Singleton
    def initialize
    end
  end
end
