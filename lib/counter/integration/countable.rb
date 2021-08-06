module Counter::Countable
  extend ActiveSupport::Concern

  included do
    # Install the Rails callbacks if required
    after_create_commit do
      each_counter_to_update do |counter|
        counter.add_item self
      end
    end

    after_update_commit do
      each_counter_to_update do |counter|
        counter.update_item self
      end
    end

    after_destroy_commit do
      each_counter_to_update do |counter|
        counter.remove_item self
      end
    end

    def each_counter_to_update
      self.class.counted_by.each do |counter_config|
        counter = association(counter_config.countable_association)
          .target.counters
          .find_counter!(counter_config.counter_class, counter_config.counting_association)
        yield counter
      end
    end
  end

  class_methods do
    def counted_by
      @counted_by
    end

    def add_counted_by config
      @counted_by ||= []
      @counted_by << config
    end
  end
end
