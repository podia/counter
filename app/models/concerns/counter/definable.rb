# Fetch the definition for a counter
# counter.definition # => Counter::Definition
module Counter::Definable
  extend ActiveSupport::Concern

  instance_methods do
    # Fetch the definition for this counter
    def definition
      parent.class.counter_configs.find { |c| c.name }
    end
  end
end
