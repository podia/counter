# == Schema Information
#
# Table name: counter_values
#
#  id          :integer          not null, primary key
#  type        :string           indexed
#  value       :integer          default(0)
#  parent_type :string           indexed => [parent_id]
#  parent_id   :integer          indexed => [parent_type]
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class ProductCounter < Counter::Value
end
