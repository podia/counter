class OrderRevenueCounter
  include Counter::Definition

  count :orders
  name :order_revenue
end
