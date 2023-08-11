# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class User < ApplicationRecord
  include Counter::Counters

  has_many :products
  has_many :premium_products, -> { premium }, class_name: "Product"
  has_many :orders

  counter ProductCounter, PremiumProductCounter, OrdersCounter, VisitsCounter
end
