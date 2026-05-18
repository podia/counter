# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AdminUser < User
end
