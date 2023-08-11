module Counter::Calculated
  extend ActiveSupport::Concern

  included do
    def calculate!
      new_value = calculate
      update! value: new_value unless new_value.nil?
    end

    def calculate
      counters = counters_for_calculation
      # If any of the counters are missing, we can't calculate
      return if counters.any?(&:nil?)

      definition.calculated_from.call(*counters)
    end

    def counters_for_calculation
      # Fetch the dependant counters
      definition.dependent_counters.map do |counter|
        parent.counters.find_counter(counter)
      end
    end
  end
end
