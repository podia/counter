class TopicReactionsCounter < Counter::Definition
  hierarchical_from PostReactionsCounter, through: :posts
end
