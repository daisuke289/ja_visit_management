# frozen_string_literal: true

class CustomerPolicy < ApplicationPolicy
  def index?
    true # ログインユーザーは全員閲覧可能（スコープで制限）
  end

  def show?
    can_access_record?
  end

  def create?
    user.admin? || user.system_admin?
  end

  def update?
    can_access_record? && (user.admin? || user.system_admin? || user.branch_id == record.branch_id)
  end

  def destroy?
    user.admin? || user.system_admin?
  end

  # CSVインポート
  def import?
    user.admin? || user.system_admin?
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
