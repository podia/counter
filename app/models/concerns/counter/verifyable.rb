module Counter::Verifyable
  extend ActiveSupport::Concern

  def correct?
    # We can't verify these values
    return true if definition.global?

    old_value, new_value = verify
    old_value == new_value
  end

  def correct!
    # We can't verify these values
    return true if definition.global?

    old_value, new_value = verify

    requires_recalculation = old_value != new_value
    update! value: new_value if requires_recalculation

    !requires_recalculation
  end

  def verify
    if definition.calculated?
      [calculate, value]
    else
      [count_by_sql, value]
    end
  end
end
