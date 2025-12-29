# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Diagnoses", type: :request do
  let(:branch) { create(:branch) }
  let(:user) { create(:user, branch: branch) }
  let(:customer) { create(:customer, branch: branch) }

  before do
    login_as user, scope: :user
  end

  describe "GET /customers/:customer_id/diagnoses" do
    it "一覧を表示できる" do
      create(:diagnosis, customer: customer, user: user)
      get customer_diagnoses_path(customer)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /customers/:customer_id/diagnoses/new" do
    it "新規フォームを表示できる" do
      get new_customer_diagnosis_path(customer)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /customers/:customer_id/diagnoses" do
    let(:valid_params) do
      {
        diagnosis: {
          title: "2024年度財産診断",
          diagnosed_on: Date.current
        }
      }
    end

    it "新規作成できる" do
      expect {
        post customer_diagnoses_path(customer), params: valid_params
      }.to change(Diagnosis, :count).by(1)
      expect(response).to redirect_to(customer_diagnosis_path(customer, Diagnosis.last))
    end

    it "無効なパラメータではエラーになる" do
      expect {
        post customer_diagnoses_path(customer), params: { diagnosis: { title: "" } }
      }.not_to change(Diagnosis, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /customers/:customer_id/diagnoses/:id" do
    let(:diagnosis) { create(:diagnosis, customer: customer, user: user) }

    it "詳細を表示できる" do
      get customer_diagnosis_path(customer, diagnosis)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /customers/:customer_id/diagnoses/:id/edit" do
    let(:diagnosis) { create(:diagnosis, customer: customer, user: user) }

    it "編集フォームを表示できる" do
      get edit_customer_diagnosis_path(customer, diagnosis)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /customers/:customer_id/diagnoses/:id" do
    let(:diagnosis) { create(:diagnosis, customer: customer, user: user) }

    it "更新できる" do
      patch customer_diagnosis_path(customer, diagnosis), params: {
        diagnosis: { title: "更新後のタイトル" }
      }
      expect(response).to redirect_to(customer_diagnosis_path(customer, diagnosis))
      expect(diagnosis.reload.title).to eq("更新後のタイトル")
    end
  end

  describe "DELETE /customers/:customer_id/diagnoses/:id" do
    let!(:diagnosis) { create(:diagnosis, customer: customer, user: user) }

    it "削除できる" do
      expect {
        delete customer_diagnosis_path(customer, diagnosis)
      }.to change(Diagnosis, :count).by(-1)
      expect(response).to redirect_to(customer_diagnoses_path(customer))
    end
  end

  context "他支店の顧客" do
    let(:other_branch) { create(:branch) }
    let(:other_customer) { create(:customer, branch: other_branch) }

    it "支店長は他支店の顧客にアクセスできない" do
      # branch_manager は自支店のみアクセス可能
      get customer_diagnoses_path(other_customer)
      expect(response).to have_http_status(:not_found)
    end
  end
end
