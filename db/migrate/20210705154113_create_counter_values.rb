class CreateCounterValues < ActiveRecord::Migration[6.1]
  def change
    create_table :counter_values do |t|
      t.string :type, index: true
      t.string :name, index: true
      t.integer :value, default: 0
      t.references :parent, polymorphic: true

      t.timestamps
    end
  end
end
