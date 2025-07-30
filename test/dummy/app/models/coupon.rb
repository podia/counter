# == Schema Information
#
# Table name: coupons
#
#  id                 :integer          not null, primary key
#  discountable_id    :integer          not null, indexed
#  discountable_type  :string           not null, indexed
#  amount             :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class Coupon < ApplicationRecord
  belongs_to :discountable, polymorphic: true
end
