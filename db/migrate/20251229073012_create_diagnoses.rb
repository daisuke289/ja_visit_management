class CreateDiagnoses < ActiveRecord::Migration[8.0]
  def change
    create_table :diagnoses do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :diagnosed_on
      t.string :title
      t.text :notes

      t.timestamps
    end
  end
end
