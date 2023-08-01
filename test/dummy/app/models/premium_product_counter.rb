class PremiumProductCounter < Counter::Definition
  count :premium_products
  raise_on_update_column :price

  on :create do
    increment_if ->(product) { product.premium? }
  end

  on :delete do
    decrement_if ->(product) { product.premium? }
  end

  on :update do
    increment_if ->(product) { product.has_changed? :price, from: ->(price) { price < 1000 }, to: ->(price) { price >= 1000 } }
    decrement_if ->(product) { product.has_changed? :price, from: ->(price) { price >= 1000 }, to: ->(price) { price < 1000 } }
  end
end
