class Topic < ApplicationRecord
  include Counter::Counters

  has_many :posts, inverse_of: :topic
  has_many :reactions, as: :reactable, inverse_of: :reactable

  counter TopicReactionsCounter
  counter TopicAllReactionsCounter
end
