module Counter::Recalculatable
  extend ActiveSupport::Concern

  def recalc!
    if definition.calculated?
      calculate!
    elsif definition.manual?
      raise Counter::Error.new("Can't recalculate a manual counter")
    else
      update!(value: recalc_value)
    end
  rescue ActiveRecord::RecordNotUnique
    self.class
      .find_by(parent_type:, parent_id:, name:)
      .update!(value: recalc_value)
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

  def recalc_value
    definition.sum? ? sum_by_sql : count_by_sql
  end
end
