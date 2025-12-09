class Post < ApplicationRecord
  include Counter::Counters

  belongs_to :topic, inverse_of: :posts
  has_many :reactions, as: :reactable, inverse_of: :reactable

  counter PostReactionsCounter
end
