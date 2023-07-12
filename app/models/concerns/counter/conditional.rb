module Counter::Conditional
  extend ActiveSupport::Concern

  included do
    def accept_item? item, on
      return true unless definition.filters
      filter = definition.filters[on]
      return unless filter

      filter.call item
    end
  end
end
