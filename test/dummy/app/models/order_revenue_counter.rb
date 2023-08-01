class OrderRevenueCounter < Counter::Definition
  count :orders, as: :order_revenue
  sum :price
  raise_on_update_column

  after_change :send_congratulations_email

  def send_congratulations_email counter, from, to
    return unless from < 1000 && to >= 1000
    puts "Congratulations! You've made #{to} dollars!"
  end
end
