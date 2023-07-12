class OrderRevenueCounter < Counter::Definition
  count :orders
  sum :price
  name :order_revenue
end
