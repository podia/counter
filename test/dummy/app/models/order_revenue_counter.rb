class OrderRevenueCounter < Counter::Definition
  count :orders, as: :order_revenue
  sum :price

  after_change ->(instance, from, to) { send_congratulations_email from, to }

  def self.send_congratulations_email from, to
    return unless from < 1000 && to >= 1000
    puts "Congratulations! You've made #{to} dollars!"
  end
end
