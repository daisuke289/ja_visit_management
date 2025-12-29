class CreateJaCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :ja_customers do |t|
      t.string :customer_number
      t.string :household_number
      t.string :name
      t.string :name_kana
      t.date :birth_date
      t.string :postal_code
      t.string :address
      t.string :phone
      t.references :branch, null: false, foreign_key: true
      t.decimal :deposit_balance
      t.decimal :loan_balance
      t.boolean :has_banking
      t.boolean :has_mutual_aid
      t.boolean :has_agriculture
      t.boolean :has_funeral
      t.boolean :has_gas
      t.boolean :has_real_estate
      t.datetime :last_synced_at

      t.timestamps
    end
    add_index :ja_customers, :customer_number, unique: true
  end
end
