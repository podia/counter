module Counter
  module RSpecMatchers
    def increment_counter_for(...)
      IncrementCounterFor.new(...)
    end

    def decrement_counter_for(...)
      DecrementCounterFor.new(...)
    end

    class Base < RSpec::Matchers::BuiltIn::Change
      def initialize(counter_class, parent)
        super { parent.counters.find_or_create_counter!(counter_class).value }
      end
    end

    class IncrementCounterFor < Base
      def matches?(...)
        by(1).matches?(...)
      end
    end

    class DecrementCounterFor < Base
      def matches?(...)
        by(-1).matches?(...)
      end
    end
  end
end
