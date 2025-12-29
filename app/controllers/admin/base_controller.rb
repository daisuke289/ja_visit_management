module Admin
  class BaseController < ApplicationController
    before_action :authorize_admin!

    private

    def authorize_admin!
      unless current_user.admin? || current_user.system_admin?
        redirect_to root_path, alert: '管理者権限が必要です。'
      end
    end
  end
end
