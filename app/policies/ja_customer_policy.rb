# frozen_string_literal: true

class JaCustomerPolicy < ApplicationPolicy
  def index?
    true # ログインユーザーは全員閲覧可能（スコープで制限）
  end

  def show?
    can_access_record?
  end

  # JA全顧客マスタは本店管理者のみ編集可能
  def create?
    user.admin? || user.system_admin?
  end

  def update?
    user.admin? || user.system_admin?
  end

  def destroy?
    user.system_admin?
  end

  # CSVインポート
  def import?
    user.admin? || user.system_admin?
  end

  # 顧客番号検索（家族構成入力時）
  def search?
    true
  end

  private

  def can_access_record?
    return true if user.can_access_all_branches?
    record.branch_id == user.branch_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.can_access_all_branches?
        scope.all
      else
        scope.by_branch(user.branch_id)
      end
    end
  end
end
