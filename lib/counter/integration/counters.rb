module Counter::Counters
  extend ActiveSupport::Concern

  included do
    has_many :counters, dependent: :destroy, class_name: "Counter::Value", as: :parent do
      # Something.counters.find_counter MyCounter
      def find_counter counter_class, name
        proxy_association.target.find { |c| c.type == counter_class.name.to_s && c.name == name.to_s }
      end

      def find_counter! counter_class, name
        counter = proxy_association.target.find { |c| c.type == counter_class.name.to_s && c.name == name.to_s }
        counter ||= Counter::Value.create_or_find_by!(parent: proxy_association.owner, type: counter_class.name, name: name)

        # Add the configuration for this counter to the instance
        counter.config = proxy_association.owner.class.counter_configs.find { |c| c.match? proxy_association.owner.class, counter.class, name }
        counter
      end
    end

    # could even be a default scope??
    scope :with_counters, -> { includes(:counters) }
  end

  class_methods do
    # keep_count_of students: SiteStudentCounter
    # keep_count_of orders: { counter: RevenueCounter, column: :price }
    def keep_count_of association_counters
      @counter_configs ||= []

      association_counters.each do |association_name, counter_class|
        column_to_count = nil

        if counter_class.is_a? Hash
          column_to_count = counter_class[:column]
          counter_class = counter_class[:counter]
        end

        # Find the association on this model
        association_reflection = reflect_on_association(association_name)
        # Find the association classes
        association_class = association_reflection.class_name.constantize
        countable_association = association_reflection.inverse_of

        # Add the after_commit hook to the association's class
        association_class.include Counter::Countable
        # Provide the Countable class with details about where it's counted
        config = Counter::AssociationCounter.new self, counter_class, association_name, countable_association.name, column_to_count
        @counter_configs << config
        association_class.add_counted_by config
      end
    end

    # Returns a list of Counter::CounterConfigs
    def counter_configs
      @counter_configs || []
    end
  end
end
