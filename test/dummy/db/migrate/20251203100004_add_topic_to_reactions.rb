class AddTopicToReactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :reactions, :topic, null: true, foreign_key: true
  end
end
