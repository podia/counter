class AddUniqueIndexToCounterValues < ActiveRecord::Migration[6.1]
  def change
    add_index :counter_values, [:parent_type, :parent_id, :type, :name],
      unique: true, name: "unique_counter_values"
  end
end
