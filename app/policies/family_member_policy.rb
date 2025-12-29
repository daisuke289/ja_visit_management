# frozen_string_literal: true

class FamilyMemberPolicy < ApplicationPolicy
  def index?
    can_access_customer?
  end

  def show?
    can_access_customer?
  end

  def create?
    can_modify_customer?
  end

  def update?
    can_modify_customer?
  end

  def destroy?
    can_modify_customer?
  end

  private

  def can_access_customer?
    return true if user.can_access_all_branches?
    record.customer.branch_id == user.branch_id
  end

  def can_modify_customer?
    return true if user.admin? || user.system_admin?
    return false unless can_access_customer?
    user.branch_id == record.customer.branch_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.can_access_all_branches?
        scope.all
      else
        scope.joins(:customer).where(customers: { branch_id: user.branch_id })
      end
    end
  end
end
