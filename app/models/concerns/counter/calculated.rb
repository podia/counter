module Counter::Calculated
  extend ActiveSupport::Concern

  included do
    def calculate!
      # Fetch the dependant counters
      counters = definition.dependent_counters.map do |counter|
        parent.counters.find_counter(counter)
      end

      # If any of the counters are missing, we can't calculate
      return if counters.any?(&:nil?)

      new_value = definition.calculated_from.call(*counters)
      update! value: new_value
    end
  end
end
