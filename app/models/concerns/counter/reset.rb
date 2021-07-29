module Counter::Reset
  extend ActiveSupport::Concern

  included do
    def reset!
      with_lock do
        update! value: 0
      end
    end
  end
end
