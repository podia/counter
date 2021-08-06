module Counter::Recalculatable
  extend ActiveSupport::Concern

  ####################################################### Support for regenerating the counters
  def recalc!
    with_lock do
      new_value = config.sum? ? sum_by_sql : count_by_sql
      perform_update! new_value - value
    end
  end

  def count_by_sql
    recalc_scope.count
  end

  def sum_by_sql
    # site.students.merge(Student.all).sum :revenue
    recalc_scope.sum(config.column_to_count)
  end

  # use this scope when recalculating the value
  def recalc_scope
    return parent.send(config.counting_association) if config.present?

    raise NotImplementedException
  end
end
