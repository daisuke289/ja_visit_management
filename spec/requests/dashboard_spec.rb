# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET / (root)" do
    context "本店管理者の場合" do
      let(:admin) { create(:user, :admin) }

      before do
        login_as admin, scope: :user
      end

      it "本店ダッシュボードを表示できる" do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("本店ダッシュボード")
      end

      it "支店別状況を表示する" do
        branch = create(:branch, name: "テスト支店")
        create(:customer, branch: branch)

        get root_path
        expect(response.body).to include("支店別状況")
        expect(response.body).to include("テスト支店")
      end

      it "未訪問30日超リストを表示する" do
        branch = create(:branch)
        customer = create(:customer, branch: branch, last_visit_date: 31.days.ago)

        get root_path
        expect(response.body).to include("未訪問30日超")
        expect(response.body).to include(customer.name)
      end

      it "週間訪問件数グラフを表示する" do
        get root_path
        expect(response.body).to include("週間訪問件数推移")
      end

      it "訪問種別グラフを表示する" do
        get root_path
        expect(response.body).to include("訪問種別")
      end
    end

    context "支店長の場合" do
      let(:branch) { create(:branch) }
      let(:user) { create(:user, :branch_manager, branch: branch) }

      before do
        login_as user, scope: :user
      end

      it "支店ダッシュボードを表示できる" do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("支店ダッシュボード")
      end

      it "統計カードを表示する" do
        create_list(:customer, 3, branch: branch)

        get root_path
        expect(response.body).to include("重要取引先数")
        expect(response.body).to include("訪問率")
      end

      it "未訪問30日超リストを表示する" do
        customer = create(:customer, branch: branch, last_visit_date: 31.days.ago)

        get root_path
        expect(response.body).to include("未訪問30日超")
        expect(response.body).to include(customer.name)
      end

      it "期限切れアクションリストを表示する" do
        customer = create(:customer, branch: branch)
        visit_type = create(:visit_type)
        visit_record = create(:visit_record, customer: customer, user: user, visit_type: visit_type)
        action = create(:action,
          customer: customer,
          user: user,
          visit_record: visit_record,
          title: "期限切れテスト",
          due_date: 1.day.ago,
          status: :pending)

        get root_path
        expect(response.body).to include("期限切れアクション")
        expect(response.body).to include("期限切れテスト")
      end

      it "今週の訪問予定を表示する" do
        customer = create(:customer, branch: branch)
        visit_type = create(:visit_type)
        plan = create(:visit_plan,
          customer: customer,
          user: user,
          visit_type: visit_type,
          planned_date: 2.days.from_now,
          status: :scheduled)

        get root_path
        expect(response.body).to include("今週の訪問予定")
        expect(response.body).to include(customer.name)
      end

      it "他支店の顧客は表示しない" do
        other_branch = create(:branch)
        other_customer = create(:customer, branch: other_branch, last_visit_date: 31.days.ago)

        get root_path
        expect(response.body).not_to include(other_customer.name)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
