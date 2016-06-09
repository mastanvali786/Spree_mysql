class CreateSpreeStoreCreditTypes < ActiveRecord::Migration
  def change
    create_table :spree_store_credit_types do |t|
      t.string :name
      t.integer :priority
      t.timestamps null: false
    end
    add_index :spree_store_credit_types, :priority
  end
end
