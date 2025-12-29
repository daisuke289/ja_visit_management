class CreateActions < ActiveRecord::Migration[8.0]
  def change
    create_table :actions do |t|
      t.references :visit_record, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.date :due_date
      t.integer :status
      t.datetime :completed_at
      t.bigint :next_visit_record_id

      t.timestamps
    end
  end
end
