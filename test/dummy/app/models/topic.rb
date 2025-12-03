class Topic < ApplicationRecord
  include Counter::Counters

  has_many :posts, inverse_of: :topic

  counter TopicReactionsCounter
end
