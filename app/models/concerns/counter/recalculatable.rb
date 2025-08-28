module Counter::Recalculatable
  extend ActiveSupport::Concern

  def recalc!
    if definition.calculated_value?
      recalculate_with_value!
    elsif definition.calculated?
      calculate!
    elsif definition.manual?
      raise Counter::Error.new("Can't recalculate a manual counter")
    else
      with_lock do
        new_value = definition.sum? ? sum_by_sql : count_by_sql
        update! value: new_value
      end
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

  private

  def recalculate_with_value!
    with_lock do
      update!(value: definition.calculated_value.call(parent))
    end
  end
end
