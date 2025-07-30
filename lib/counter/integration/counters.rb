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
        definition.model = self

        counter_subquery = ->(counter_class) do
          record_name = counter_class.instance.record_name

          Counter::Value
            .select(:value)
            .where("parent_id = #{table_name}.id AND parent_type = '#{name}' AND name = '#{record_name}'")
            .limit(1)
            .to_sql
        end

        scope :with_counter_data_from, ->(*counter_classes) {
          subqueries = ["#{table_name}.*"]

          counter_classes.each do |counter_class|
            subquery = counter_subquery.call(counter_class)
            subqueries << Arel.sql("(#{subquery}) AS #{"#{counter_class.instance.name}_data"}")
          end

          select(subqueries)
        }

        # Expects a hash of counter classes and directions, like so:
        # order_by_counter ProductCounter => :desc, PremiumProductCounter => :asc
        scope :order_by_counter, ->(order_hash) {
          counter_classes = order_hash.keys.select { |counter_class|
            counter_class.is_a?(Class) &&
              counter_class.ancestors.include?(Counter::Definition)
          }

          order_clauses = order_hash.map do |counter_class, direction|
            if counter_class.is_a?(String) || counter_class.is_a?(Symbol)
              "#{counter_class} #{direction.to_s.upcase}"
            elsif counter_class.ancestors.include?(Counter::Definition)
              "(#{counter_subquery.call(counter_class)}) #{direction.to_s.upcase}"
            end
          end

          with_counter_data_from(*counter_classes).order(Arel.sql(order_clauses.join(", ")))
        }

        scope :with_counters, -> { includes(:counters) }

        define_method definition.method_name do
          counters.find_or_create_counter!(definition)
        end

        @counter_configs << definition unless @counter_configs.include?(definition)

        association_name = definition.association_name
        if association_name.present?
          # Find the association on this model
          association_reflection = reflect_on_association(association_name)
          raise Counter::Error.new("#{association_name} does not exist #{self.name}") if association_reflection.nil?

          # Find the association classes
          association_class = association_reflection.class_name.constantize
          inverse_association = association_reflection.inverse_of
          raise Counter::Error.new("#{association_name} must have an inverse_of specified to be used in #{definition_class.name}") if inverse_association.nil?

          # Add the after_commit hook to the association's class
          association_class.include Counter::Countable

          # Update the definition with the association class and inverse association
          # gathered from the reflection
          definition.inverse_association = inverse_association.name
          definition.countable_model = association_class

          # Provide the Countable class with details about where it's counted
          association_class.add_counted_by definition
        end
      end
    end

    # Returns a list of Counter::Definitions
    def counter_configs
      @counter_configs || []
    end
  end
end
