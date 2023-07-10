module Counter::Xhierarchical
  extend ActiveSupport::Concern

  ########################################################## Support hierarchy of counters
  # e.g. a open counter for an email > a newsletter > a drip_campaign > a site
  def counters_to_update
    [self] + dependant_counters.flat_map { |c| c.counters_to_update }
  end

  # Override this to add other counters
  def dependant_counters
    []
  end

  def perform_update! increment
    Counter.increment_all! counters_to_update, by: increment
  end

  # In a single SQL transaction, increment the counters
  def self.increment_all! counters, by: 1
    Counter.lock.where(id: counters).update_all! "value = value + ?, updated_at: NOW()", by
  end
end
