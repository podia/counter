module Counter::Verifyable
  extend ActiveSupport::Concern

  def correct?
    # We can't verify these values
    return true if definition.global?

    old_value, new_value = verify
    old_value == new_value
  end

  def correct!
    # We can't verify these values
    return true if definition.global?

    old_value, new_value = verify

    requires_recalculation = old_value != new_value
    update! value: new_value if requires_recalculation

    !requires_recalculation
  end

  def verify
    if definition.calculated?
      [calculate, value]
    else
      [count_by_sql, value]
    end
  end

  class_methods do
    # on_error: raise, log, correct
    # Returns the number of incorrect counters
    def sample_and_verify scope: -> { all }, samples: 1000, verbose: true, on_error: :raise
      incorrect_counters = 0

      counter_range = Counter::Value.minimum(:id)..Counter::Value.maximum(:id)

      samples.times do
        random_id = rand(counter_range)
        counter = Counter::Value.merge(scope).where("id >= ?", random_id).limit(1).first
        next if counter.nil?

        if counter.definition.global? || counter.definition.calculated?
          puts "➡️ Skipping counter #{counter.name} (#{counter.id})" if verbose
          next
        end

        if counter.correct?
          puts "✅ Counter #{counter.id} is correct" if verbose
        else
          incorrect_counters += 1
          message = "❌ counter #{counter.name} (#{counter.id}) for #{counter.parent_type}##{counter.parent_id} has incorrect counter value. Expected #{counter.value} but got #{counter.count_by_sql}"

          case on_error
          when :raise then raise Counter::Error.new(message)
          when :log then Rails.logger.error message
          when :correct then counter.correct!
          end
        end
        sleep 0.1
      end
      incorrect_counters
    end
  end
end
