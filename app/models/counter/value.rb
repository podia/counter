# == Schema Information
#
# Table name: counter_values
#
#  id          :integer          not null, primary key
#  type        :string           indexed
#  name        :string           indexed
#  value       :integer          default(0)
#  parent_type :string           indexed => [parent_id]
#  parent_id   :integer          indexed => [parent_type]
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Counter::Value < ApplicationRecord
  def self.table_name_prefix
    "counter_"
  end

  belongs_to :parent, polymorphic: true, optional: true

  validates_numericality_of :value

  def self.find_counter counter
    counter_name = if counter.is_a?(String) || counter.is_a?(Symbol)
      counter.to_s
    elsif counter.is_a?(Class) && counter.ancestors.include?(Counter::Definition)
      definition = counter.instance
      raise "Unable to find counter #{definition.name} via Counter::Value.find_counter. Use must use #{definition.model}#find_counter}" unless definition.global?

      counter.instance.record_name
    else
      counter.to_s
    end

    find_or_initialize_by name: counter_name
  end

  include Counter::Definable
  include Counter::Increment
  include Counter::Reset
  include Counter::Recalculatable
  include Counter::Verifyable
  include Counter::Summable
  include Counter::Conditional
  # include Counter::Hierarchical
end
