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

    # Iterate over each counter that needs to be updated for this model
    # expects a block that takes a counter as an argument
    def each_counter_to_update
      # For each definition, find or create the counter on the parent
      self.class.counted_by.each do |counter_definition|
        parent_model = association(counter_definition.inverse_association)
          .target
        counter = parent_model.counters.find_or_create_counter!(counter_definition)
        yield counter if counter
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
