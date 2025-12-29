class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :set_current_branch

  # Pundit例外ハンドリング
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_current_branch
    @current_branch = current_user&.branch
  end

  def user_not_authorized
    flash[:alert] = "この操作を行う権限がありません。"
    redirect_back(fallback_location: root_path)
  end

  # 支店スコープを適用したCustomerを返す
  def accessible_customers
    if current_user.can_access_all_branches?
      Customer.all
    else
      Customer.by_branch(current_user.branch_id)
    end
  end

  # 支店スコープを適用したJaCustomerを返す
  def accessible_ja_customers
    if current_user.can_access_all_branches?
      JaCustomer.all
    else
      JaCustomer.by_branch(current_user.branch_id)
    end
  end
end
