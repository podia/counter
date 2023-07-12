module Counter::Verifyable
  extend ActiveSupport::Concern

  def correct?
    count_by_sql == value
  end

  def correct!
    requires_recalculation = !correct?
    recalc! if requires_recalculation

    !requires_recalculation
  end
end
