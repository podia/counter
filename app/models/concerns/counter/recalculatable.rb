module Counter::Recalculatable
  extend ActiveSupport::Concern

  ####################################################### Support for regenerating the counters
  def recalc!
    with_lock do
      new_value = definition.sum? ? sum_by_sql : count_by_sql
      update! value: new_value
    end
  end

  def count_by_sql
    recalc_scope.count
  end

  def sum_by_sql
    recalc_scope.sum(definition.column_to_count)
  end

  # use this scope when recalculating the value
  def recalc_scope
    parent.association(definition.association_name).scope
  end
end
