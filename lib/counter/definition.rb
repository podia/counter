# Example usage…
#
# class ProductCounter
#   include Counter::Definition
#   # This specifies the association we're counting
#   count :products
#   sum :price   # optional
#   as "my_counter"
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
  # The counters this calculated counter depends on
  attr_writer :dependent_counters
  # The block to call to calculate the counter
  attr_accessor :calculated_from
  # The block used to manually set the value
  attr_accessor :calculated_value
  # The counter's record name
  attr_writer :record_name

  # Is this a counter which sums a column?
  def sum?
    column_to_count.present?
  end

  # Is this a global counter? i.e., not attached to a model
  def global?
    model.nil?
  end

  # Is this counter conditional?
  def conditional?
    @conditional
  end

  # Is this counter using a calculated value?
  def calculated_value?
    @calculated_value.present?
  end

  # Is this counter calculated from other counters?
  def calculated?
    !@calculated_from.nil?
  end

  # Is this a manual counter?
  # Manual counters are not automatically updated from an association
  # or calculated from other counters
  def manual?
    association_name.nil? && !calculated?
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

  def self.record_name(value)
    instance.record_name = value.to_s
  end

  # What we record in Counter::Value#name
  def record_name
    return @record_name if @record_name.present?
    return name if global?
    return "#{model.name.underscore}-#{association_name}" if association_name.present?
    "#{model.name.underscore}-#{name}"
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

  def dependent_counters
    @dependent_counters ||= []
    @dependent_counters
  end

  # Set the association we're counting
  def self.count association_name, as: "#{association_name}_counter"
    instance.association_name = association_name
    instance.name = as.to_s
    # How the counter can be accessed e.g. counter.products_counter
    instance.method_name = as.to_s
  end

  def self.calculated_value(calculation, association: nil)
    instance.association_name = association
    instance.calculated_value = calculation
    set_default_name
  end

  def self.set_default_name
    instance.name ||= to_s.underscore
    instance.method_name ||= to_s.underscore
  end

  def self.global
    Counter::Definition.instance.global_counters << instance
  end

  def self.calculated_from *dependent_counters, &block
    instance.dependent_counters = dependent_counters
    instance.calculated_from = block

    dependent_counters.each do |dependent_counter|
      # Install after_change hooks on the dependent counters
      dependent_counter.after_change :update_calculated_counters
      dependent_counter.define_method :update_calculated_counters do |counter, _old_value, _new_value|
        # Fetch all the counters which depend on this one
        calculated_counters = counter.parent.class.counter_configs.select { |c|
          c.dependent_counters.include?(counter.definition.class)
        }

        calculated_counters = calculated_counters.map { |c| counter.parent.counters.find_or_create_counter!(c) }
        # calculate the new values
        calculated_counters.each(&:calculate!)
      end
    end
  end

  # Set the name of the counter
  def self.as name
    instance.name = name.to_s
    instance.method_name = name.to_s
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
end
