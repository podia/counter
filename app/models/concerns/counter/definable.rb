# Fetch the definition for a counter
# counter.definition # => Counter::Definition
module Counter::Definable
  extend ActiveSupport::Concern

  included do
    # Fetch the definition for this counter
    def definition
      parent.class.counter_configs.find { |c| c.counter_value_name == name }
    end
  end
end
