class ProductDiscountsCounter < Counter::Definition
  count :coupons, as: :product_discounts
  sum :amount
end
