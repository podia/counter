# == Schema Information
#
# Table name: counter_values
#
#  id          :bigint(8)        not null, primary key
#  parent_type :string           indexed => [parent_id]
#  type        :string           indexed
#  value       :integer          default(0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  parent_id   :bigint(8)        indexed => [parent_type]
#
class Counter::Value < ApplicationRecord
  def self.table_name_prefix
    "counter_"
  end

  belongs_to :parent, polymorphic: true, optional: true
  has_many :updates, class_name: "Counter::Change", dependent: :delete_all

  validates_numericality_of :value

  include Counter::Increment
  include Counter::Reset
  include Counter::Conditional
  include Counter::Hierarchical
  include Counter::Recalculatable
  include Counter::Summable
end
