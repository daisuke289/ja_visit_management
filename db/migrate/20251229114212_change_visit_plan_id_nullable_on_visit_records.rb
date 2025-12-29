class ChangeVisitPlanIdNullableOnVisitRecords < ActiveRecord::Migration[8.0]
  def change
    change_column_null :visit_records, :visit_plan_id, true
  end
end
