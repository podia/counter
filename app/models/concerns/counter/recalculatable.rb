module Counter::Recalculatable
  extend ActiveSupport::Concern

  def recalc!
    if definition.calculated?
      calculate!
    elsif definition.manual?
      raise Counter::Error.new("Can't recalculate a manual counter")
    else
      with_lock do
        new_value = definition.sum? ? sum_by_sql : count_by_sql

        self.class.upsert(
          attributes.without("id", "created_at", "updated_at").symbolize_keys.merge(value: new_value),
          unique_by: [:parent_type, :parent_id, :name],
          on_duplicate: Arel.sql("value = counter_values.value + EXCLUDED.value"),
          record_timestamps: true
        )

        reload
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
end
