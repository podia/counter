class AddGrumpyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :grumpy, :boolean, default: false
  end
end
