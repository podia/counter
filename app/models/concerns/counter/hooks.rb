# Allow hooks to be defined on the counter
module Counter::Hooks
  extend ActiveSupport::Concern

  included do
    after_update :call_counter_hooks

    def call_counter_hooks
      return unless previous_changes["value"]

      from, to = previous_changes["value"]
      definition.counter_hooks.each do |hook|
        hook.call self, from, to
      end
    end
  end
end
