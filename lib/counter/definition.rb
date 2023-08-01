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
  # Test if we should count items using conditions
  attr_writer :conditions
  attr_writer :conditional
  # Set the name of the counter (used as the method name)
  attr_accessor :method_name
  attr_accessor :name
  # An array of all global counters
  attr_writer :global_counters
  # An array of Proc to run when the counter changes
  attr_writer :counter_hooks
  # An array of columns that should raise an error if update_column is called
  attr_accessor :raisable_columns

  def sum?
    column_to_count.present?
  end

  def global?
    model.nil? && association_name.nil?
  end

  def conditional?
    @conditional
  end

  # for global counter instances to find their definition
  def self.find_definition name
    Counter::Definition.instance.global_counters.find { |c| c.name == name }
  end

  # Access the counter value for global counters
  def self.counter
    raise "Unable to find counter instances via #{name}#counter. Use must use #{instance.model}#find_counter or #{instance.model}##{instance.counter_name}" unless instance.global?

    Counter::Value.find_counter self
  end

  # What we record in Counter::Value#name
  def record_name
    return name if global?
    "#{model.name.underscore}-#{association_name}"
  end

  def conditions
    @conditions ||= {}
    @conditions
  end

  def global_counters
    @global_counters ||= []
    @global_counters
  end

  def counter_hooks
    @counter_hooks ||= []
    @counter_hooks
  end

  # Set the association we're counting
  def self.count association_name, as: "#{association_name}_counter"
    instance.association_name = association_name
    instance.name = as.to_s
    # How the counter can be accessed e.g. counter.products_counter
    instance.method_name = as.to_s
  end

  def self.global name = nil
    name ||= name.underscore
    instance.name = name.to_s
    Counter::Definition.instance.global_counters << instance
  end

  # Get the name of the association we're counting
  def self.association_name
    instance.association_name
  end

  # Set the column we're summing. Leave blank to count the number of items
  def self.sum column_name
    instance.column_to_count = column_name
  end

  # Define a conditional filter
  def self.on action, &block
    instance.conditional = true

    conditions = Counter::Conditions.new
    conditions.instance_eval(&block)

    instance.conditions[action] ||= []
    instance.conditions[action] << conditions
  end

  def self.after_change block
    instance.counter_hooks << block
  end

  # Prevent calling update_column on these columns
  def self.raise_on_update_column *columns
    columns ||= []
    columns = columns.map(&:to_sym)
    instance.raisable_columns = columns
  end
end
