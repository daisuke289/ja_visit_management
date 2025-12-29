# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # 未訪問顧客の検索最適化
    add_index :customers, :last_visit_date, name: "index_customers_on_last_visit_date"

    # 期限切れアクションの検索最適化（複合インデックス）
    add_index :actions, [ :status, :due_date ], name: "index_actions_on_status_and_due_date"

    # 訪問計画の期間検索最適化（複合インデックス）
    add_index :visit_plans, [ :status, :planned_date ], name: "index_visit_plans_on_status_and_planned_date"

    # 訪問記録の期間検索最適化
    add_index :visit_records, [ :customer_id, :visited_at ], name: "index_visit_records_on_customer_and_visited_at"
  end
end
