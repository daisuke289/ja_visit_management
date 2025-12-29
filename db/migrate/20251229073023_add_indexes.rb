class AddIndexes < ActiveRecord::Migration[8.0]
  def change
    # JaCustomer
    add_index :ja_customers, :household_number
    add_index :ja_customers, :name_kana

    # Customer
    add_index :customers, :household_number
    add_index :customers, :name_kana

    # FamilyMember
    add_index :family_members, :ja_customer_number
    add_index :family_members, :parent_member_id
    add_index :family_members, :spouse_member_id

    # VisitPlan
    add_index :visit_plans, :planned_date
    add_index :visit_plans, :status

    # VisitRecord
    add_index :visit_records, :visited_at

    # Action
    add_index :actions, :due_date
    add_index :actions, :status
    add_index :actions, :next_visit_record_id
  end
end
