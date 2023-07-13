# Example usage…
#
# class ProductCounter
#   include Counter::Definition
#   # This specifies the association we're counting
#   count :products
#   sum :price   # optional
#   filters: {   # optional
#     create: ->(product) { product.premium? }
#     update: ->(product) { product.has_changed? :premium, to: :true }
#     delete: ->(product) { product.premium? }
#   }
# end
class Counter::Definition
  include Singleton

  # Attributes set by Counters#counter integration:
  attr_accessor :association_name
  # Set the model we're attached to (set by Counters#counter)
  attr_accessor :model
  # Set the thing we're counting (set by Counters#counter)
  attr_accessor :countable_model
  # Set the inverse association (i.e., from the products to the user)
  attr_accessor :inverse_association
  # When using sum, set the column we're summing
  attr_accessor :column_to_count
  # Conditionally count items using filters
  attr_accessor :filters
  # Set the name of the counter (used as the method name)
  attr_writer :counter_name

  def sum?
    column_to_count.present?
  end

  def counter_name
    @counter_name || "#{association_name}_counter"
  end

  # Get the name of this counter e.g. user_products
  def counter_value_name
    "#{model.name.underscore}-#{association_name}"
  end

  # Set the association we're counting
  def self.count association_name
    instance.association_name = association_name
  end

  # Get the name of the association we're counting
  def self.association_name
    instance.association_name
  end

  # Set the name of the counter (used as the method name)
  def self.name name
    instance.counter_name = name.to_s
  end

  # Set the column we're summing. Leave blank to count the number of items
  def self.sum column_name
    instance.column_to_count = column_name
  end

  # Define a conditional filter
  def self.conditional filters
    instance.filters = filters
  end
end
