# == Schema Information
#
# Table name: counter_changes
#
#  id               :bigint(8)        not null, primary key
#  amount           :integer
#  processed_at     :datetime         indexed
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  counter_value_id :bigint(8)        indexed
#
class Counter::Change < ApplicationRecord
  def self.table_name_prefix
    "counter_"
  end

  belongs_to :counter, class_name: "Counter::Value"
  validates_numericality_of :amount

  scope :unreconciled, -> { where(reconciled_at: nil) }
  scope :reconciled, -> { where.not(reconciled_at: nil) }
  scope :purgable, -> { reconciled.where(processed_at: 7.days.ago..) }
end
