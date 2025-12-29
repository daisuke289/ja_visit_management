# frozen_string_literal: true

class VisitPlansController < ApplicationController
  before_action :set_customer, only: [ :new, :create, :show, :edit, :update, :destroy ]
  before_action :set_visit_plan, only: [ :show, :edit, :update, :destroy ]

  # 全顧客横断の訪問計画一覧
  def index
    @visit_plans = policy_scope(VisitPlan)
                     .includes(:customer, :user, :visit_type)
                     .order(:planned_date)

    # 支店フィルタ
    if params[:branch_id].present? && current_user.can_access_all_branches?
      @visit_plans = @visit_plans.by_branch(params[:branch_id])
    end

    # ステータスフィルタ
    case params[:status]
    when "scheduled"
      @visit_plans = @visit_plans.scheduled
    when "overdue"
      @visit_plans = @visit_plans.overdue
    when "completed"
      @visit_plans = @visit_plans.completed
    when "cancelled"
      @visit_plans = @visit_plans.cancelled
    else
      @visit_plans = @visit_plans.scheduled.or(VisitPlan.overdue)
    end

    # 期間フィルタ
    if params[:from].present?
      @visit_plans = @visit_plans.where("planned_date >= ?", params[:from])
    end
    if params[:to].present?
      @visit_plans = @visit_plans.where("planned_date <= ?", params[:to])
    end

    @visit_plans = @visit_plans.page(params[:page]).per(20)
    @branches = Branch.ordered if current_user.can_access_all_branches?
  end

  def show
    authorize @visit_plan
  end

  def new
    @visit_plan = @customer.visit_plans.build
    @visit_plan.user = current_user
    @visit_plan.planned_date = Date.current
    @visit_plan.status = :scheduled
    authorize @visit_plan
    @visit_types = VisitType.active.ordered
  end

  def create
    @visit_plan = @customer.visit_plans.build(visit_plan_params)
    @visit_plan.user = current_user
    authorize @visit_plan

    if @visit_plan.save
      redirect_to customer_path(@customer), notice: "訪問計画を登録しました。"
    else
      @visit_types = VisitType.active.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @visit_plan
    @visit_types = VisitType.active.ordered
  end

  def update
    authorize @visit_plan

    if @visit_plan.update(visit_plan_params)
      redirect_to customer_path(@customer), notice: "訪問計画を更新しました。"
    else
      @visit_types = VisitType.active.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @visit_plan

    if @visit_plan.visit_record.present?
      redirect_to customer_path(@customer), alert: "訪問記録が紐付いているため削除できません。"
    else
      @visit_plan.destroy
      redirect_to customer_path(@customer), notice: "訪問計画を削除しました。"
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_visit_plan
    @visit_plan = @customer.visit_plans.find(params[:id])
  end

  def visit_plan_params
    params.require(:visit_plan).permit(
      :visit_type_id, :planned_date, :planned_time, :purpose, :status
    )
  end
end
