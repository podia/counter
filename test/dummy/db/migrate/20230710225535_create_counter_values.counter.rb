# This migration comes from counter (originally 20210705154113)
class CreateCounterValues < ActiveRecord::Migration[6.1]
  def change
    create_table :counter_values do |t|
      t.string :name, index: true
      t.float :value, default: 0
      t.references :parent, polymorphic: true

      t.timestamps
    end
  end
end
