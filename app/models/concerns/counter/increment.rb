module Counter::Increment
  extend ActiveSupport::Concern

  included do
    def increment! by: 1
      perform_update! by
    end

    def decrement! by: 1
      perform_update!(-by)
    end

    def perform_update! increment
      return if increment.zero?

      with_lock do
        update! value: value + increment
      end
    end

    def add_item item
      return unless accept_item?(item, :create)

      increment! by: increment_from_item(item)
    end

    def remove_item item
      return unless accept_item?(item, :delete)

      decrement! by: increment_from_item(item)
    end

    def update_item item
      return unless definition.filters && definition.filters[:update]

      change = definition.filters[:update].call item
      increment! by: change * increment_from_item(item)
    end

    # How much should we increment the counter
    def increment_from_item item
      1
    end
  end
end
