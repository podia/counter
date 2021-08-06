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
  has_many :updates, class_name: "Counter::Change", dependent: :delete_all

  validates_numericality_of :value

  include Counter::Configurable
  include Counter::Increment
  include Counter::Reset
  include Counter::Hierarchical
  include Counter::Recalculatable
  include Counter::Summable
end
