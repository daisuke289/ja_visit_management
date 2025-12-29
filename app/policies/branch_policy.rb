# frozen_string_literal: true

class BranchPolicy < ApplicationPolicy
  def index?
    user.admin? || user.system_admin?
  end

  def show?
    user.can_access_all_branches? || record.id == user.branch_id
  end

  def create?
    user.system_admin?
  end

  def update?
    user.system_admin?
  end

  def destroy?
    user.system_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.can_access_all_branches?
        scope.all
      else
        scope.where(id: user.branch_id)
      end
    end
  end
end
