# Fetch the definition for a counter
# counter.definition # => Counter::Definition
module Counter::Definable
  extend ActiveSupport::Concern

  included do
    # Fetch the definition for this counter
    def definition
      if parent.nil?
        # We don't have a parent, so we're a global counter
        Counter::Definition.find_definition name
      else
        parent.class.counter_configs.find { |c| c.record_name == name }
      end
    end
  end
end
