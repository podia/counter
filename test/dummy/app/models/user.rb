# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class User < ApplicationRecord
  has_many :products
  has_many :orders

  include Counter::Counters
  keep_count_of products: ProductCounter
  keep_count_of orders: {counter: Counter::Value, column: :price}
end
