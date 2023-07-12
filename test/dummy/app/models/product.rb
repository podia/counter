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
class Product < ApplicationRecord
  include Counter::Counters

  belongs_to :user
  has_many :orders

  scope :premium, -> { where("price >= 1000") }
  counter OrderRevenueCounter
end
