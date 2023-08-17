# == Schema Information
#
# Table name: products
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null, indexed
#  name       :string
#  price      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class SpecialProduct < Product
end
