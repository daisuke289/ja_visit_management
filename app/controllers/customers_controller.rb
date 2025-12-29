class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  def index
    @customers = policy_scope(Customer)
                   .includes(:branch)
                   .order(:name_kana)

    # 検索
    if params[:q].present?
      @customers = @customers.search(params[:q])
    end

    # 支店フィルタ（本店管理者用）
    if params[:branch_id].present? && current_user.can_access_all_branches?
      @customers = @customers.by_branch(params[:branch_id])
    end

    # 訪問状況フィルタ
    case params[:visit_status]
    when 'never'
      @customers = @customers.where(last_visit_date: nil)
    when 'overdue'
      @customers = @customers.unvisited_for(30)
    when 'warning'
      @customers = @customers.where('last_visit_date >= ? AND last_visit_date < ?', 30.days.ago, 14.days.ago)
    end

    @customers = @customers.page(params[:page]).per(20)

    # 支店一覧（フィルタ用）
    @branches = Branch.ordered if current_user.can_access_all_branches?
  end

  def show
    authorize @customer
  end

  def new
    @customer = Customer.new
    @customer.branch = current_user.branch unless current_user.can_access_all_branches?
    authorize @customer
  end

  def create
    @customer = Customer.new(customer_params)
    authorize @customer

    # 支店長は自分の支店のみ
    unless current_user.can_access_all_branches?
      @customer.branch = current_user.branch
    end

    if @customer.save
      redirect_to @customer, notice: '重要取引先を登録しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @customer
  end

  def update
    authorize @customer

    if @customer.update(customer_params)
      redirect_to @customer, notice: '重要取引先を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @customer

    @customer.destroy
    redirect_to customers_path, notice: '重要取引先を削除しました。'
  end

  # JA全顧客マスタから情報を同期
  def sync_from_ja
    @customer = Customer.find(params[:id])
    authorize @customer, :update?

    if @customer.sync_from_ja_customer!
      redirect_to @customer, notice: 'JA顧客マスタから情報を同期しました。'
    else
      redirect_to @customer, alert: '同期元のJA顧客データが見つかりません。'
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(
      :customer_number, :household_number, :name, :name_kana,
      :postal_code, :address, :phone, :branch_id
    )
  end
end
