class CreateFamilyMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :family_members do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :name
      t.string :name_kana
      t.date :birth_date
      t.string :relationship
      t.integer :relationship_type
      t.integer :generation
      t.boolean :is_living
      t.boolean :is_cohabitant
      t.string :address
      t.string :phone
      t.string :occupation
      t.string :workplace
      t.string :ja_customer_number
      t.text :notes
      t.bigint :parent_member_id
      t.bigint :spouse_member_id
      t.integer :marriage_status

      t.timestamps
    end
  end
end
