class Counter::ReconciliationJob
  include Sidekiq::Worker

  def perform counter_id
    counter = Counter::Value.find(counter_id)
    changes = Counter::Change.where(counter: counter).pending
    changes.with_lock do
      counter.increment! changes.sum(increment)
      changes.update_all processed: Time.now
    end
  end
end
