class PremiumProductCounter < Counter::Definition
  count :premium_products
  conditional create: ->(product) { product.premium? },
    update: ->(product) {
      product.has_changed? :price,
        from: ->(price) { price < 1000 },
        to: ->(price) { price >= 1000 }
    },
    delete: ->(product) { product.premium? }
end
