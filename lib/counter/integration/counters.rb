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
          counter.instance.record_name
        else
          counter.to_s
        end

        find_by name: counter_name
      end

      # user.counters.find_counter ProductCounter
      def find_or_create_counter! counter
        counter_name = if counter.is_a?(String) || counter.is_a?(Symbol)
          counter.to_s
        elsif counter.is_a?(Counter::Definition)
          counter.record_name
        elsif counter.is_a?(Class) && counter.ancestors.include?(Counter::Definition)
          counter.instance.record_name
        else
          counter.to_s
        end

        Counter::Value.find_or_initialize_by(parent: proxy_association.owner, name: counter_name)
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
      counter_definitions.each do |definition_class|
        definition = definition_class.instance
        association_name = definition.association_name

        # Find the association on this model
        association_reflection = reflect_on_association(association_name)
        # Find the association classes
        association_class = association_reflection.class_name.constantize
        inverse_association = association_reflection.inverse_of

        raise Counter::Error.new("#{association_name} must have an inverse_of specified to be used in #{definition_class.name}") if inverse_association.nil?

        # Add the after_commit hook to the association's class
        association_class.include Counter::Countable
        # association_class.include Counter::Changed

        # Update the definition with the association class and inverse association
        # gathered from the reflection
        definition.model = self
        definition.inverse_association = inverse_association.name
        definition.countable_model = association_class

        define_method definition.method_name do
          counters.find_or_create_counter!(definition)
        end

        @counter_configs << definition

        # Provide the Countable class with details about where it's counted
        association_class.add_counted_by definition

        if definition.raisable_columns
          # Prevent the countable class from having update_columns called on it in dev/test
          if Rails.env.development? || Rails.env.test?
            association_class.define_method :update_columns do |attributes|
              if definition.raisable_columns.empty? || (definition.raisable_columns & attributes.symbolize_keys.keys).any?
                raise Counter::Error.new "WARNING: #{self.class.name}#update_columns is called and won't update the counter #{definition.name}"
              end

              super(attributes)
            end
          end
        end
      end
    end

    # Returns a list of Counter::Definitions
    def counter_configs
      @counter_configs || []
    end
  end
end
