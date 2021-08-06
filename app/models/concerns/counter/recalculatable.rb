module Counter::Recalculatable
  extend ActiveSupport::Concern

  ####################################################### Support for regenerating the counters
  def recalc!
    with_lock do
      old_value = value
      new_value = count_by_sql
      perform_update! new_value - old_value
    end
  end

  def count_by_sql
    # site.students.merge(Student.all).count
    recalc_scope.count
  end

  def sum_by_sql
    # site.students.merge(Student.all).sum :revenue
    recalc_scope.sum(column_name)
  end

  # use this scope when recalculating the value
  def recalc_scope
    return parent.send(config.counting_association) if config.present?

    raise NotImplementedException
  end
end
