class CreateVisitPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :visit_plans do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :visit_type, null: false, foreign_key: true
      t.date :planned_date
      t.time :planned_time
      t.text :purpose
      t.integer :status

      t.timestamps
    end
  end
end
