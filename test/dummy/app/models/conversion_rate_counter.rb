class ConversionRateCounter < Counter::Definition
  count nil, as: "conversion_rate"

  calculated_from VisitsCounter, OrdersCounter do |visits, orders|
    (orders.value.to_f / visits.value) * 100
  end
end
