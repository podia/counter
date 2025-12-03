class Post < ApplicationRecord
  include Counter::Counters

  belongs_to :topic, inverse_of: :posts
  has_many :reactions, inverse_of: :post

  counter PostReactionsCounter
end
