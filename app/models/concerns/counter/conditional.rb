module Counter::Conditional
  extend ActiveSupport::Concern

  included do
    def count_filter method, on, &block
      case on
      when :create
      when :update
      when :destroy
      end

      @count_filters ||= {}
      @count_filters[on] ||= []
      @count_filters[on] << (block || method)
    end
  end

  ########################################################## Support for conditional aggregation
  def add_item item
    super if filter_item(item, :create)
  end

  def update_item item
    # has_changed?(attribute, from: this, to: that)
    super if filter_item(item, :update)
  end

  def remove_item item
    super if filter_item(item, :remove)
  end

  private

  def filter_item item, on
    filters = @@count_filters[:create] || []
    filters.all? do |filter|
      case filter.class
      when Symbol
        send filter, items
      when Proc
        instance_exec items, filter
      end
    end
  end

  def has_changed? attribute, from: Any.new, to: Any.new
    old_value, new_value = previous_changes[attribute]
    # Return true if the attribute changed at all
    return true if from.instance_of?(Any) && to.instance_of?(Any)

    return new_value == to if from.instance_of?(Any)
    return old_value == from if to.instance_of?(Any)

    old_value == from && new_value == to
  end

  class Any
    include Singleton
    def initialize
    end
  end
end
