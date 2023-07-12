# Example usage…
#
# class ProductCounter
#   include Counter::Definition
#   # This specifies the association we're counting
#   count :products
#   sum :price   # optional
#   filters: {   # optional
#     create: ->(product) { product.premium? }
#     update: ->(product) { product.has_changed? :premium, to: :true }
#     delete: ->(product) { product.premium? }
#   }
# end
module Counter::Definition
  extend ActiveSupport::Concern

  class_methods do
    # Attributes set by Counters#counter integration:

    # Set the model we're attached to (set by Counters#counter)
    attr_accessor :model
    # Set the thing we're counting (set by Counters#counter)
    attr_accessor :countable_model
    # Set the inverse association (i.e., from the products to the user)
    attr_accessor :inverse_association
    # When using sum, set the column we're summing
    attr_accessor :column_to_count

    # Set the association we're counting
    def count association_name
      @association_name = association_name
    end

    def association_name
      @association_name
    end

    # Get the name of this counter e.g. user_products
    def counter_value_name
      "#{@model.name.underscore}-#{@association_name}"
    end

    def name name
      @counter_name = name.to_s
    end

    def counter_name
      @counter_name || "#{@association_name}_counter"
    end

    # Set the column we're summing
    def sum column_name
      @column_to_count = column_name
    end

    def sum?
      column_to_count.present?
    end
  end
end
