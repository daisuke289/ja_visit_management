# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Calendar", type: :request do
  let(:branch) { create(:branch) }
  let(:user) { create(:user, :branch_manager, branch: branch) }
  let(:admin) { create(:user, :admin) }
  let(:customer) { create(:customer, branch: branch) }
  let(:visit_type) { create(:visit_type) }

  describe "GET /calendar" do
    context "支店長の場合" do
      before do
        login_as user, scope: :user
      end

      it "成功する" do
        get calendar_path
        expect(response).to have_http_status(:success)
      end

      it "カレンダーページを表示する" do
        get calendar_path
        expect(response.body).to include("訪問カレンダー")
      end

      it "今月の訪問計画を表示する" do
        plan = create(:visit_plan,
                      customer: customer,
                      user: user,
                      visit_type: visit_type,
                      planned_date: Date.current)

        get calendar_path
        expect(response.body).to include(customer.name)
      end

      it "他の月にナビゲートできる" do
        get calendar_path(start_date: 1.month.ago.to_date)
        expect(response).to have_http_status(:success)
      end

      it "他支店の計画は表示しない" do
        other_branch = create(:branch)
        other_customer = create(:customer, branch: other_branch)
        plan = create(:visit_plan,
                      customer: other_customer,
                      user: admin,
                      visit_type: visit_type,
                      planned_date: Date.current)

        get calendar_path
        expect(response.body).not_to include(other_customer.name)
      end
    end

    context "本店管理者の場合" do
      before do
        login_as admin, scope: :user
      end

      it "全支店の計画を表示する" do
        other_branch = create(:branch)
        other_customer = create(:customer, branch: other_branch)
        plan = create(:visit_plan,
                      customer: other_customer,
                      user: admin,
                      visit_type: visit_type,
                      planned_date: Date.current)

        get calendar_path
        expect(response.body).to include(other_customer.name)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        get calendar_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /calendar/ical" do
    before do
      login_as user, scope: :user
    end

    it "iCalファイルを返す" do
      create(:visit_plan,
             customer: customer,
             user: user,
             visit_type: visit_type,
             planned_date: 1.week.from_now)

      get calendar_ical_path
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/calendar")
      expect(response.headers["Content-Disposition"]).to include("visit_plans.ics")
    end

    it "予定されている訪問計画を含む" do
      plan = create(:visit_plan,
                    customer: customer,
                    user: user,
                    visit_type: visit_type,
                    planned_date: 1.week.from_now,
                    status: :scheduled)

      get calendar_ical_path
      expect(response.body).to include(customer.name)
    end

    it "VCALENDAR形式である" do
      create(:visit_plan,
             customer: customer,
             user: user,
             visit_type: visit_type,
             planned_date: 1.week.from_now)

      get calendar_ical_path
      expect(response.body).to include("BEGIN:VCALENDAR")
      expect(response.body).to include("END:VCALENDAR")
    end
  end
end
