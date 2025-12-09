class MakeReactionsPolymorphic < ActiveRecord::Migration[8.0]
  def change
    # Remove old foreign keys and columns
    remove_reference :reactions, :post, foreign_key: true
    remove_reference :reactions, :topic, foreign_key: true

    # Add polymorphic reference
    add_reference :reactions, :reactable, polymorphic: true, null: false
  end
end
