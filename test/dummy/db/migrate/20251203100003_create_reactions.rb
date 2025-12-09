class CreateReactions < ActiveRecord::Migration[8.0]
  def change
    create_table :reactions do |t|
      t.references :post, null: true, foreign_key: true
      t.string :emoji
      t.timestamps
    end
  end
end
