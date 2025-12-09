require "test_helper"

class HierarchicalTest < ActiveSupport::TestCase
  test "hierarchical counter increments when child counter increments" do
    topic = Topic.create!(title: "Test Topic")
    post = topic.posts.create!(content: "Test Post")

    topic_counter = topic.topic_reactions_counter
    topic_counter.save! if topic_counter.new_record?

    post_counter = post.reactions_counter
    post_counter.save! if post_counter.new_record?

    assert_equal 0, topic_counter.value
    assert_equal 0, post_counter.value

    post.reactions.create!(emoji: "👍")

    assert_equal 1, post_counter.reload.value
    assert_equal 1, topic_counter.reload.value
  end

  test "hierarchical counter increments correctly with multiple posts" do
    topic = Topic.create!(title: "Test Topic")
    post1 = topic.posts.create!(content: "Post 1")
    post2 = topic.posts.create!(content: "Post 2")

    topic_counter = topic.topic_reactions_counter
    topic_counter.save! if topic_counter.new_record?

    post1.reactions.create!(emoji: "👍")
    post1.reactions.create!(emoji: "❤️")
    post2.reactions.create!(emoji: "🎉")

    assert_equal 2, post1.reactions_counter.reload.value
    assert_equal 1, post2.reactions_counter.reload.value
    assert_equal 3, topic_counter.reload.value
  end

  test "hierarchical counter decrements when child counter decrements" do
    topic = Topic.create!(title: "Test Topic")
    post = topic.posts.create!(content: "Test Post")

    topic_counter = topic.topic_reactions_counter
    topic_counter.save! if topic_counter.new_record?

    reaction1 = post.reactions.create!(emoji: "👍")
    reaction2 = post.reactions.create!(emoji: "❤️")

    assert_equal 2, topic_counter.reload.value

    reaction1.destroy!

    assert_equal 1, post.reactions_counter.reload.value
    assert_equal 1, topic_counter.reload.value
  end

  test "hierarchical counter can be recalculated" do
    topic = Topic.create!(title: "Test Topic")
    post1 = topic.posts.create!(content: "Post 1")
    post2 = topic.posts.create!(content: "Post 2")

    post1.reactions.create!(emoji: "👍")
    post1.reactions.create!(emoji: "❤️")
    post2.reactions.create!(emoji: "🎉")

    topic_counter = topic.topic_reactions_counter
    topic_counter.update!(value: 0)

    assert_equal 0, topic_counter.value

    topic_counter.recalc!

    assert_equal 3, topic_counter.reload.value
  end

  test "include_direct counts direct association on parent" do
    topic = Topic.create!(title: "Test Topic")
    post = topic.posts.create!(content: "Post 1")

    post.reactions.create!(emoji: "👍")
    post.reactions.create!(emoji: "❤️")

    topic.reactions.create!(emoji: "🎉")
    topic.reactions.create!(emoji: "🔥")
    topic.reactions.create!(emoji: "👏")

    topic_all_counter = topic.topic_all_reactions_counter

    assert_equal 5, topic_all_counter.reload.value
  end

  test "include_direct recalc counts both child counters and direct association" do
    topic = Topic.create!(title: "Test Topic")
    post = topic.posts.create!(content: "Post 1")

    post.reactions.create!(emoji: "👍")
    post.reactions.create!(emoji: "❤️")

    topic.reactions.create!(emoji: "🎉")
    topic.reactions.create!(emoji: "🔥")

    Counter::Value.delete_all

    topic_all_counter = topic.topic_all_reactions_counter
    topic_all_counter.save!
    topic_all_counter.recalc!

    assert_equal 4, topic_all_counter.reload.value
  end

  test "hierarchical? returns true for hierarchical counters" do
    assert TopicReactionsCounter.instance.hierarchical?
    assert_not PostReactionsCounter.instance.hierarchical?
  end

  test "child counter knows about hierarchical parents" do
    Topic.new
    Post.new

    post_counter_def = PostReactionsCounter.instance

    assert post_counter_def.hierarchical_parents.size >= 1

    parent_config = post_counter_def.hierarchical_parents.first
    assert_equal :topic, parent_config[:via]
  end

  test "recalc! on hierarchical counter triggers recalc on missing child counters" do
    topic = Topic.create!(title: "Test Topic")
    post1 = topic.posts.create!(content: "Post 1")
    post2 = topic.posts.create!(content: "Post 2")

    Reaction.create!(reactable: post1, emoji: "👍")
    Reaction.create!(reactable: post1, emoji: "❤️")
    Reaction.create!(reactable: post2, emoji: "🎉")

    Counter::Value.delete_all

    assert_equal 0, Counter::Value.count

    topic_counter = topic.topic_reactions_counter
    topic_counter.save!
    topic_counter.recalc!

    assert_equal 3, topic_counter.reload.value
    assert_equal 2, post1.reactions_counter.reload.value
    assert_equal 1, post2.reactions_counter.reload.value
  end

  test "without_propagation skips hierarchical propagation" do
    topic = Topic.create!(title: "Test Topic")
    post = topic.posts.create!(content: "Post 1")

    topic_counter = topic.topic_reactions_counter
    topic_counter.save!
    post_counter = post.reactions_counter
    post_counter.save!

    assert_equal 0, topic_counter.value

    post_counter.without_propagation do
      post_counter.increment!
      post_counter.increment!
    end

    assert_equal 2, post_counter.reload.value
    assert_equal 0, topic_counter.reload.value, "Parent should not be updated inside without_propagation"
  end

  test "child recalc! triggered by parent recalc! does not propagate back up" do
    topic = Topic.create!(title: "Test Topic")
    post = topic.posts.create!(content: "Post 1")

    Reaction.create!(reactable: post, emoji: "👍")
    Reaction.create!(reactable: post, emoji: "❤️")

    topic_counter = topic.topic_reactions_counter
    topic_counter.save!
    post_counter = post.reactions_counter

    assert_equal 2, topic_counter.reload.value
    assert_equal 2, post_counter.reload.value

    post_counter.update!(value: 0)
    topic_counter.update!(value: 0)

    topic_counter.recalc!

    assert_equal 2, topic_counter.reload.value, "Parent should have correct value after recalc"
  end

  test "recalc! on leaf counter propagates to parent counter" do
    topic = Topic.create!(title: "Test Topic")
    post = topic.posts.create!(content: "Test Post")

    post.reactions.create!(emoji: "👍")
    post.reactions.create!(emoji: "❤️")

    topic_counter = topic.topic_reactions_counter
    post_counter = post.reactions_counter

    assert_equal 2, topic_counter.reload.value
    assert_equal 2, post_counter.reload.value

    post_counter.update!(value: 0)
    topic_counter.reload

    assert_equal 0, topic_counter.value

    post_counter.recalc!

    assert_equal 2, post_counter.reload.value
    assert_equal 2, topic_counter.reload.value
  end
end
