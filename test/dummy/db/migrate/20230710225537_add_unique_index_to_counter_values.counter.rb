# This migration comes from counter (originally 20210731224504)
class AddUniqueIndexToCounterValues < ActiveRecord::Migration[6.1]
  def change
    add_index :counter_values, [:parent_type, :parent_id, :name],
      unique: true, name: "unique_counter_values"
  end
end
