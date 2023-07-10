module Counter::Conditional
  extend ActiveSupport::Concern

  included do
    def accept_item? item, on
      config.filters[on].all? do |filter|
        case filter.class
        when Symbol
          send filter, item
        when Proc
          instance_exec item, filter
        end
      end
    end

    def has_changed? attribute, from: Counter::Any.new, to: Counter::Any.new
      old_value, new_value = previous_changes[attribute]
      # Return true if the attribute changed at all
      return true if from.instance_of?(Any) && to.instance_of?(Any)

      return new_value == to if from.instance_of?(Any)
      return old_value == from if to.instance_of?(Any)

      old_value == from && new_value == to
    end
  end
end
