class CreateVisitRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :visit_records do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :visit_type, null: false, foreign_key: true
      t.datetime :visited_at
      t.string :interviewee
      t.text :content
      t.text :customer_situation
      t.references :visit_plan, null: false, foreign_key: true

      t.timestamps
    end
  end
end
