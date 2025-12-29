# frozen_string_literal: true

class ActionPolicy < ApplicationPolicy
  def create?
    can_access_customer?
  end

  def update?
    can_access_record?
  end

  def destroy?
    can_access_record? && record.pending?
  end

  private

  def can_access_record?
    return true if user.can_access_all_branches?
    record.customer.branch_id == user.branch_id
  end

  def can_access_customer?
    return true if user.can_access_all_branches?
    customer = record.respond_to?(:customer) ? record.customer : record
    customer.branch_id == user.branch_id
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
