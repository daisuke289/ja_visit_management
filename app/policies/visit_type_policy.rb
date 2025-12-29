# frozen_string_literal: true

class VisitTypePolicy < ApplicationPolicy
  # 訪問種別マスタはsystem_adminのみ管理可能
  def index?
    user.system_admin?
  end

  def show?
    user.system_admin?
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
      scope.all
    end
  end
end
