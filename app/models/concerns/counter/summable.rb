# count_using :price
# count_using ->{ revenue * priority }
# This lets you keep running totals of revenue etc rather than just a count of the orders
module Counter::Summable
  extend ActiveSupport::Concern

  included do
    def count_using attribute = nil, &block
      @count_using_attribute = attribute
      # TODO: Maybe remove the block and just call a method?
      @count_using_block = block
    end
  end

  def increment_from_item item
    if @@count_using_block
      instance_exec @@count_using_block
    else
      item.send @@count_using_attribute
    end
  end

  # TODO: Should only override this if Recalculatable
  def count_by_sql
    recalc_scope.sum(@@count_using)
  end
end
