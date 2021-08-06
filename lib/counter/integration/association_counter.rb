class Counter::AssociationCounter
  attr_reader :parent_class, :counter_class, :counting_association, :countable_association, :column_to_count

  def initialize(parent_class, counter_class, counting_association, countable_association, column = nil)
    @parent_class = parent_class
    @counter_class = counter_class
    @counting_association = counting_association
    @countable_association = countable_association
    @column_to_count = column
  end

  def match? parent_class, counter_class, counting_association
    self.parent_class == parent_class &&
      self.counter_class == counter_class &&
      self.counting_association == counting_association
  end

  def sum?
    column_to_count.present?
  end
end
