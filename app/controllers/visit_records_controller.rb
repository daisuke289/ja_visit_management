# frozen_string_literal: true

class VisitRecordsController < ApplicationController
  before_action :set_customer, only: [ :new, :create, :show, :edit, :update, :destroy ]
  before_action :set_visit_record, only: [ :show, :edit, :update, :destroy ]

  # 全顧客横断の訪問記録一覧
  def index
    @visit_records = policy_scope(VisitRecord)
                       .includes(:customer, :user, :visit_type)
                       .recent

    # 支店フィルタ
    if params[:branch_id].present? && current_user.can_access_all_branches?
      @visit_records = @visit_records.by_branch(params[:branch_id])
    end

    # 訪問種別フィルタ
    if params[:visit_type_id].present?
      @visit_records = @visit_records.by_visit_type(params[:visit_type_id])
    end

    # 期間フィルタ
    if params[:from].present? && params[:to].present?
      @visit_records = @visit_records.in_period(Date.parse(params[:from]), Date.parse(params[:to]))
    elsif params[:from].present?
      @visit_records = @visit_records.where("visited_at >= ?", params[:from])
    elsif params[:to].present?
      @visit_records = @visit_records.where("visited_at <= ?", Date.parse(params[:to]).end_of_day)
    end

    @visit_records = @visit_records.page(params[:page]).per(20)
    @branches = Branch.ordered if current_user.can_access_all_branches?
    @visit_types = VisitType.active.ordered
  end

  def show
    authorize @visit_record
  end

  def new
    @visit_record = @customer.visit_records.build
    @visit_record.user = current_user
    @visit_record.visited_at = Time.current

    # 計画から作成する場合
    if params[:visit_plan_id].present?
      @visit_plan = @customer.visit_plans.find(params[:visit_plan_id])
      @visit_record.visit_plan = @visit_plan
      @visit_record.visit_type = @visit_plan.visit_type
    end

    authorize @visit_record
    @visit_types = VisitType.active.ordered
  end

  def create
    @visit_record = @customer.visit_records.build(visit_record_params)
    @visit_record.user = current_user
    authorize @visit_record

    if @visit_record.save
      # 次アクションの作成
      if params[:next_action].present? && params[:next_action][:title].present?
        @visit_record.create_next_action!(
          title: params[:next_action][:title],
          due_date: params[:next_action][:due_date]
        )
      end

      redirect_to customer_path(@customer), notice: "訪問記録を登録しました。"
    else
      @visit_types = VisitType.active.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @visit_record
    @visit_types = VisitType.active.ordered
  end

  def update
    authorize @visit_record

    if @visit_record.update(visit_record_params)
      redirect_to customer_visit_record_path(@customer, @visit_record), notice: "訪問記録を更新しました。"
    else
      @visit_types = VisitType.active.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @visit_record

    if @visit_record.actions.any?
      redirect_to customer_path(@customer), alert: "次アクションが紐付いているため削除できません。"
    else
      @visit_record.destroy
      redirect_to customer_path(@customer), notice: "訪問記録を削除しました。"
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_visit_record
    @visit_record = @customer.visit_records.find(params[:id])
  end

  def visit_record_params
    params.require(:visit_record).permit(
      :visit_type_id, :visit_plan_id, :visited_at, :interviewee,
      :content, :customer_situation, attachments: []
    )
  end
end
