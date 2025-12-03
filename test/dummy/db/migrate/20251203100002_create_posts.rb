class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :topic, null: false, foreign_key: true
      t.text :content
      t.timestamps
    end
  end
end
