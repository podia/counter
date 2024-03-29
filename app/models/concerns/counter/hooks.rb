# Allow hooks to be defined on the counter
module Counter::Hooks
  extend ActiveSupport::Concern

  included do
    after_save :call_counter_hooks

    def call_counter_hooks
      return unless previous_changes["value"]

      from, to = previous_changes["value"]
      definition.counter_hooks.each do |hook|
        definition.send(hook, self, from, to)
      end
    end
  end
end
