module Counter::Conditional
  extend ActiveSupport::Concern

  included do
    def increment? item, on
      accept_item? item, on, increment: true
    end

    def decrement? item, on
      accept_item? item, on, increment: false
    end

    def accept_item? item, on, increment: true
      return true unless definition.conditional?

      conditions = definition.conditions[on]
      return true unless conditions

      conditions.any? do |conditions|
        if increment
          conditions.increment_conditions.any? do |condition|
            return true if condition.call(item)
          end
        else
          conditions.decrement_conditions.any? do |condition|
            return true if condition.call(item)
          end
        end
      end
    end
  end
end
