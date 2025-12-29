class DashboardController < ApplicationController
  def show
    if current_user.can_access_all_branches?
      # 本店ダッシュボード
      render :admin
    else
      # 支店ダッシュボード
      render :branch
    end
  end

  private

  # 本店ダッシュボード用データ
  def admin_dashboard_data
    @branches = Branch.ordered.includes(:customers)

    # 支店別統計
    @branch_stats = @branches.map do |branch|
      {
        branch: branch,
        customer_count: branch.customers.count,
        visit_rate: branch.visit_rate,
        overdue_actions: branch.overdue_actions_count
      }
    end

    # 全体統計
    @total_customers = Customer.count
    @total_visited_30days = Customer.where("last_visit_date >= ?", 30.days.ago).count
    @total_overdue_actions = Action.where(status: :pending).where("due_date < ?", Date.current).count
    @unvisited_30days = Customer.unvisited_for(30).limit(10)
  end
  helper_method :admin_dashboard_data

  # 支店ダッシュボード用データ
  def branch_dashboard_data
    branch = current_user.branch
    return {} unless branch

    @customers = branch.customers.order(:last_visit_date).limit(10)
    @upcoming_plans = VisitPlan.joins(:customer)
                               .where(customers: { branch_id: branch.id })
                               .where(status: :scheduled)
                               .where(planned_date: Date.current..7.days.from_now)
                               .order(:planned_date)
                               .limit(10)
    @overdue_actions = Action.joins(:customer)
                             .where(customers: { branch_id: branch.id })
                             .where(status: :pending)
                             .where("due_date < ?", Date.current)
                             .order(:due_date)
                             .limit(10)
    @unvisited_30days = branch.customers.unvisited_for(30).limit(10)

    # 統計
    @customer_count = branch.customers.count
    @visit_rate = branch.visit_rate
    @overdue_count = @overdue_actions.count
  end
  helper_method :branch_dashboard_data
end
