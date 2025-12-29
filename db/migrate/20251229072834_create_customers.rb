class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :customer_number
      t.string :household_number
      t.string :name
      t.string :name_kana
      t.string :postal_code
      t.string :address
      t.string :phone
      t.references :branch, null: false, foreign_key: true
      t.date :last_visit_date

      t.timestamps
    end
    add_index :customers, :customer_number, unique: true
  end
end
