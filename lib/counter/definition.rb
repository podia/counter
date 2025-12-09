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

  # Hierarchical counter attributes
  # Child definitions this counter aggregates from
  attr_writer :hierarchical_children
  # Parent definitions this counter propagates to
  attr_writer :hierarchical_parents

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
    association_name.nil? && !calculated? && !hierarchical?
  end

  # Is this a hierarchical counter?
  # Hierarchical counters aggregate values from child counters
  def hierarchical?
    hierarchical_children.present?
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

  def hierarchical_children
    @hierarchical_children ||= []
    @hierarchical_children
  end

  def hierarchical_parents
    @hierarchical_parents ||= []
    @hierarchical_parents
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

  # Define a hierarchical counter that aggregates from child counters
  #
  # Usage:
  #   class TopicReactionsCounter < Counter::Definition
  #     hierarchical_from PostReactionsCounter, through: :posts
  #   end
  #
  # The parent counter will:
  # - Automatically update when child counters change (via delta propagation)
  # - Support recalc! by summing all child counter values
  #
  # @param child_counter_class [Class] The child counter definition class
  # @param through [Symbol] The association name on the parent model to reach children
  # @param include_direct [Symbol, nil] Optional association on the parent to also count directly
  def self.hierarchical_from(child_counter_class, through:, include_direct: nil)
    child_def = child_counter_class.instance
    parent_def = instance

    parent_def.hierarchical_children << {
      child_definition_class: child_counter_class,
      through: through,
      include_direct: include_direct
    }

    Counter::Definition.register_pending_hierarchical(parent_def)

    set_default_name
  end

  # Wire up the hierarchical relationship after the parent model is set
  # Called from Counter::Counters.counter
  def wire_hierarchical_relationship!
    return unless hierarchical?

    hierarchical_children.each do |config|
      child_counter_class = config[:child_definition_class]
      through = config[:through]
      include_direct = config[:include_direct]

      child_def = child_counter_class.instance

      parent_reflection = model.reflect_on_association(through)
      raise Counter::Error, "Unknown association #{through} on #{model.name}" if parent_reflection.nil?

      inverse_on_child = parent_reflection.inverse_of
      raise Counter::Error, "#{through} on #{model.name} must declare inverse_of to be used hierarchically" if inverse_on_child.nil?

      via_on_child = inverse_on_child.name

      already_wired = child_def.hierarchical_parents.any? { |p| p[:parent_definition] == self }
      next if already_wired

      child_def.hierarchical_parents << {
        parent_definition_class: self.class,
        parent_definition: self,
        via: via_on_child
      }

      wire_direct_association!(include_direct) if include_direct
    end
  end

  # Wire up callbacks for the direct association (include_direct option)
  def wire_direct_association!(direct_association)
    direct_reflection = model.reflect_on_association(direct_association)
    raise Counter::Error, "Unknown association #{direct_association} on #{model.name}" if direct_reflection.nil?

    direct_class = direct_reflection.class_name.constantize
    inverse_of_direct = direct_reflection.inverse_of
    raise Counter::Error, "#{direct_association} on #{model.name} must declare inverse_of" if inverse_of_direct.nil?

    direct_class.include Counter::Countable unless direct_class.respond_to?(:counted_by)

    self.inverse_association = inverse_of_direct.name
    self.countable_model = direct_class
    direct_class.add_counted_by(self)
  end

  # Registry of hierarchical definitions waiting for their child counters
  @pending_hierarchical_definitions = []

  def self.pending_hierarchical_definitions
    @pending_hierarchical_definitions ||= []
  end

  def self.register_pending_hierarchical(definition)
    pending_hierarchical_definitions << definition unless pending_hierarchical_definitions.include?(definition)
  end

  # Called when a child counter is registered to check if any parent counters
  # are waiting to wire to it
  def self.wire_pending_hierarchical_parents!
    pending_hierarchical_definitions.each do |definition|
      next unless definition.model.present?
      definition.wire_hierarchical_relationship!
    end
  end
end
