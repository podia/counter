class CreateCoupons < ActiveRecord::Migration[7.0]
  def change
    create_table :coupons do |t|
      t.references :discountable, polymorphic: true, null: false
      t.integer :amount

      t.timestamps
    end
  end
end
