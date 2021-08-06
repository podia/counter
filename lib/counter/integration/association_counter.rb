class Counter::AssociationCounter
  attr_reader :parent_class, :counter_class, :counting_association, :countable_association

  def initialize(parent_class, counter_class, counting_association, countable_association)
    @parent_class = parent_class
    @counter_class = counter_class
    @counting_association = counting_association
    @countable_association = countable_association
  end

  def match? parent_class, counter_class, counting_association
    self.parent_class == parent_class &&
      self.counter_class == counter_class &&
      self.counting_association == counting_association
  end
end
