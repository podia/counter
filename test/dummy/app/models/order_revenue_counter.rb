class OrderRevenueCounter < Counter::Definition
  count :orders, as: :order_revenue
  sum :price
end
