class PremiumProductCounter < Counter::Definition
  count :premium_products
  conditional create: ->(product) { product.premium? },
    delete: ->(product) { product.premium? },
    update: ->(product) {
      became_premium = product.has_changed? :price,
        from: ->(price) { price < 1000 },
        to: ->(price) { price >= 1000 }
      return 1 if became_premium

      became_not_premium = product.has_changed? :price,
        from: ->(price) { price >= 1000 },
        to: ->(price) { price < 1000 }
      return -1 if became_not_premium

      return 0
    }
end
