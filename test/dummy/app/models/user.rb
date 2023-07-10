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
  has_many :orders

  counter ProductCounter
end
