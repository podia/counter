class ReturnedOrderCounter < Counter::Definition
  calculated_value ->(order) { 500 }, association: :orders
  record_name :users_returned_orders
end
