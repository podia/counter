# count_using :price
# count_using ->{ revenue * priority }
# This lets you keep running totals of revenue etc rather than just a count of the orders
module Counter::Summable
  extend ActiveSupport::Concern

  included do
    # Replace Increment#increment_from_item
    def increment_from_item item
      return item.send definition.column_to_count if definition.sum?

      1
    end
  end
end
