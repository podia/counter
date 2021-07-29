module Counter::SidekiqReconciliation
  extend ActiveSupport::Concern

  ########################################################## Support for background reconciliation
  def add_item item
    record_counter_change
    enqueue_reconcilitation_job
  end

  def update_item item
    record_counter_change amount: 1
    enqueue_reconcilitation_job
  end

  def remove_item item
    record_counter_change amount: -1
    enqueue_reconcilitation_job
  end

  private

  def record_counter_change amount: 1
    Counter::Change.create! counter: self, increment: amount
  end

  # Enqueue a Sidekiq job
  def enqueue_reconcilitation_job
    Counter::ReconciliationJob.perform_now id
  end

  def filter_item item, on
    filtered_items = []
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
