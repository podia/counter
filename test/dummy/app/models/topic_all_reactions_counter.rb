class TopicAllReactionsCounter < Counter::Definition
  hierarchical_from PostReactionsCounter, through: :posts, include_direct: :reactions
end
