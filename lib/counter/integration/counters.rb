module Counter::Counters
  extend ActiveSupport::Concern

  included do
    has_many :counters, dependent: :destroy do
      # Something.counters.find_counter MyCounter
      def find_counter counter_class, name
        proxy_association.target.find { |c| c.type == counter_class.name.to_s && c.name == name }
      end
    end

    # could even be a default scope??
    scope :with_counters, -> { includes(:counters) }
  end

  class_methods do
    # keep_count_of students: SiteStudentCounter
    def keep_count_of association_counters
      association_counters.each do |association_name, counter_class|
        # Find the association on this model
        association_reflection = reflect_on_association(association_name)
        # Find the association classes
        association_class = association_reflection.class_name.constantize
        inverse_association = association_reflection.inverse_of

        # Add the after_commit hook to the association's class
        association_class.include Counter::Countable
        association_class.add_counted_by self, counter_class, association_name, inverse_association

        # Install the Rails callbacks if required
        association_class.after_commit do
          # Actually update the counter
          association(inverse_association).counters.find_counter(counter_class).update it
        end
      end
    end
  end
end
