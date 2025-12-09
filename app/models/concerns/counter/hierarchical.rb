module Counter::Hierarchical
  extend ActiveSupport::Concern

  included do
    after_save :propagate_hierarchical_changes, if: :saved_change_to_value?

    thread_mattr_accessor :skip_hierarchical_propagation, default: false
  end

  def without_propagation
    previous_value = Counter::Value.skip_hierarchical_propagation
    Counter::Value.skip_hierarchical_propagation = true
    yield
  ensure
    Counter::Value.skip_hierarchical_propagation = previous_value
  end

  def propagate_hierarchical_changes
    return if Counter::Value.skip_hierarchical_propagation
    return unless definition.present?
    return if definition.hierarchical_parents.empty?

    old_value, new_value = saved_change_to_value
    delta = new_value - old_value
    return if delta.zero?

    definition.hierarchical_parents.each do |config|
      parent_assoc_name = config[:via]
      parent_definition = config[:parent_definition]

      next unless parent_definition

      parent_record = parent&.public_send(parent_assoc_name)
      next unless parent_record

      next unless parent_record.class.reflect_on_association(:counters)

      parent_counter = parent_record.counters.find_or_create_counter!(parent_definition)
      parent_counter.save! if parent_counter.new_record?
      parent_counter.perform_update!(delta)
    end
  end

  def recalc_hierarchical!
    config = definition.hierarchical_children.first
    raise Counter::Error, "No hierarchical_children configured" unless config

    child_def_class = config[:child_definition_class]
    child_def = child_def_class.instance
    through = config[:through]
    include_direct = config[:include_direct]

    recalc_child_counters!(child_def, through)

    parent_model = definition.model
    child_model = child_def.model

    parent_reflection = parent_model.reflect_on_association(through)
    child_foreign_key = parent_reflection.foreign_key

    child_table = child_model.table_name
    cv_table = Counter::Value.table_name

    new_value = Counter::Value
      .joins("JOIN #{child_table} ON #{child_table}.id = #{cv_table}.parent_id")
      .where(
        "#{cv_table}.parent_type" => child_model.name,
        "#{cv_table}.name" => child_def.record_name
      )
      .where("#{child_table}.#{child_foreign_key}" => parent.id)
      .sum(:value)

    if include_direct
      new_value += parent.public_send(include_direct).count
    end

    with_lock do
      update!(value: new_value)
    end
  end

  private

  def recalc_child_counters!(child_def, through)
    without_propagation do
      parent.public_send(through).find_each do |child_record|
        child_counter = child_record.counters.find_or_create_counter!(child_def)
        child_counter.recalc!
      end
    end
  end
end
