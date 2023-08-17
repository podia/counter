# Fetch the definition for a counter
# counter.definition # => Counter::Definition
module Counter::Definable
  extend ActiveSupport::Concern

  included do
    def definition= definition
      @definition = definition
    end

    # Fetch the definition for this counter
    def definition
      @definition ||= begin
        if parent.nil?
          # We don't have a parent, so we're a global counter
          Counter::Definition.find_definition name
        else
          parent.class.ancestors.find do |ancestor|
            return nil if ancestor == ApplicationRecord
            next unless ancestor.respond_to?(:counter_configs)
            config = ancestor.counter_configs.find { |c| c.record_name == name }
            return config if config
          end
        end
      end
    end
  end
end
