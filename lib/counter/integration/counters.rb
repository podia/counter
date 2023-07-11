# This should be included in the model that has the counter
# e.g.
# class User < ApplicationModel
#   include Counter::Counters
#   has_many products
#   counter ProductCounter
# end

require "counter/definition"

module Counter::Counters
  extend ActiveSupport::Concern

  included do
    has_many :counters, dependent: :destroy, class_name: "Counter::Value", as: :parent do
      # user.counters.find_counter ProductCounter
      def find_counter counter
        counter_name = if counter.is_a?(String) || counter.is_a?(Symbol)
          counter.to_s
        elsif counter.is_a?(Class) && counter.ancestors.include?(Counter::Definition)
          counter.counter_value_name
        else
          counter.to_s
        end

        find_by name: counter_name
      end

      # user.counters.find_counter ProductCounter
      def find_or_create_counter! counter
        counter_name = if counter.is_a?(String) || counter.is_a?(Symbol)
          counter.to_s
        elsif counter.is_a?(Class) && counter.ancestors.include?(Counter::Definition)
          counter.counter_value_name
        else
          counter.to_s
        end

        Counter::Value.create_or_find_by!(parent: proxy_association.owner, name: counter_name)
      end
    end

    # could even be a default scope??
    scope :with_counters, -> { includes(:counters) }
  end

  class_methods do
    # counter ProductCounter
    # counter PremiumProductCounter, FreeProductCounter
    def counter *counter_definitions
      @counter_configs ||= []

      counter_definitions = Array.wrap(counter_definitions)

      counter_definitions.each do |definition|
        association_name = definition.association_name

        # Find the association on this model
        association_reflection = reflect_on_association(association_name)
        # Find the association classes
        association_class = association_reflection.class_name.constantize
        inverse_association = association_reflection.inverse_of

        # Add the after_commit hook to the association's class
        association_class.include Counter::Countable
        # association_class.include Counter::Changed

        # Update the definition with the association class and inverse association
        # gathered from the reflection
        definition.model = self
        definition.inverse_association = inverse_association.name
        definition.countable_model = association_class

        define_method definition.counter_name do
          counters.find_or_create_counter!(definition)
        end

        # Provide the Countable class with details about where it's counted

        @counter_configs << definition
        association_class.add_counted_by definition
      end
    end

    # Returns a list of Counter::Definitions
    def counter_configs
      @counter_configs || []
    end
  end
end
