class CreateCounterChanges < ActiveRecord::Migration[6.1]
  def change
    create_table :counter_changes do |t|
      t.references :counter_value, foreign_key: true
      t.integer :amount
      t.timestamp :processed_at, index: true

      t.timestamps
    end
  end
end
