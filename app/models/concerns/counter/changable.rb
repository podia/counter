module Counter::Changable
  extend ActiveSupport::Concern

  included do
    def has_changed? attribute, from: Any.instance, to: Any.instance
      return false unless previous_changes.key?(attribute)

      old_value, new_value = previous_changes[attribute]

      # Return true on any changes
      return true if from.instance_of?(Any) && to.instance_of?(Any)

      from_condition = case from
      when Any then true
      when Proc then from.call(old_value)
      else
        from == old_value
      end

      to_condition = case to
      when Any then true
      when Proc then to.call(new_value)
      else
        to == new_value
      end

      # # Return false if nothing changed
      # return false if old_value == new_value

      # # Check if the value change from <something>
      # return new_value == to if from.instance_of?(Any)
      # # Check if the value change to <something>
      # return old_value == from if to.instance_of?(Any)

      # Check if the value change from <something> to <something>
      from_condition && to_condition
    end
  end

  class Any
    include Singleton
  end
end
