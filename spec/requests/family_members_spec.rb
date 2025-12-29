# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FamilyMembers", type: :request do
  let(:branch) { create(:branch) }
  let(:user) { create(:user, branch: branch) }
  let(:customer) { create(:customer, branch: branch) }

  before do
    login_as user, scope: :user
  end

  describe "GET /customers/:customer_id/family_members" do
    it "一覧を表示できる" do
      create(:family_member, customer: customer)
      get customer_family_members_path(customer)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /customers/:customer_id/family_members/new" do
    it "新規フォームを表示できる" do
      get new_customer_family_member_path(customer)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /customers/:customer_id/family_members" do
    let(:valid_params) do
      {
        family_member: {
          name: "テスト家族",
          relationship: "配偶者",
          relationship_type: "spouse",
          is_living: true
        }
      }
    end

    it "新規作成できる" do
      expect {
        post customer_family_members_path(customer), params: valid_params
      }.to change(FamilyMember, :count).by(1)
      expect(response).to redirect_to(customer_family_members_path(customer))
    end

    it "無効なパラメータではエラーになる" do
      expect {
        post customer_family_members_path(customer), params: { family_member: { name: "" } }
      }.not_to change(FamilyMember, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /customers/:customer_id/family_members/:id/edit" do
    let(:family_member) { create(:family_member, customer: customer) }

    it "編集フォームを表示できる" do
      get edit_customer_family_member_path(customer, family_member)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /customers/:customer_id/family_members/:id" do
    let(:family_member) { create(:family_member, customer: customer) }

    it "更新できる" do
      patch customer_family_member_path(customer, family_member), params: {
        family_member: { name: "更新後の名前" }
      }
      expect(response).to redirect_to(customer_family_members_path(customer))
      expect(family_member.reload.name).to eq("更新後の名前")
    end
  end

  describe "DELETE /customers/:customer_id/family_members/:id" do
    let!(:family_member) { create(:family_member, customer: customer) }

    it "削除できる" do
      expect {
        delete customer_family_member_path(customer, family_member)
      }.to change(FamilyMember, :count).by(-1)
      expect(response).to redirect_to(customer_family_members_path(customer))
    end
  end

  context "他支店の顧客" do
    let(:other_branch) { create(:branch) }
    let(:other_customer) { create(:customer, branch: other_branch) }

    it "支店長は他支店の顧客にアクセスできない" do
      # branch_manager は自支店のみアクセス可能
      get customer_family_members_path(other_customer)
      expect(response).to have_http_status(:not_found)
    end
  end
end
