module Counter::Countable
  extend ActiveSupport::Concern

  included do
    after_commit :update_counter

    def update_counters
      counted_by.each do |parent_class, counter_class, association_name|
      end
      # Find the counter
      association(association_name).reader.counters(counter_name).increment!
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
