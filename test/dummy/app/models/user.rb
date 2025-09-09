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
  has_many :subscriptions

  counter ProductCounter, PremiumProductCounter, OrdersCounter, VisitsCounter
  counter ConversionRateCounter
  counter CigaretteCounter
  counter ReturnedOrderCounter

  def grumpy! = update!(grumpy: true)
end
