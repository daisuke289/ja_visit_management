# frozen_string_literal: true

require "rails_helper"

RSpec.describe Diagnosis, type: :model do
  describe "バリデーション" do
    let(:customer) { create(:customer) }
    let(:user) { create(:user, branch: customer.branch) }

    it "有効なファクトリ" do
      diagnosis = build(:diagnosis, customer: customer, user: user)
      expect(diagnosis).to be_valid
    end

    it "診断日は必須" do
      diagnosis = build(:diagnosis, customer: customer, user: user, diagnosed_on: nil)
      expect(diagnosis).not_to be_valid
      expect(diagnosis.errors[:diagnosed_on]).to include("を入力してください")
    end

    it "タイトルは必須" do
      diagnosis = build(:diagnosis, customer: customer, user: user, title: nil)
      expect(diagnosis).not_to be_valid
      expect(diagnosis.errors[:title]).to include("を入力してください")
    end
  end

  describe "スコープ" do
    let(:customer) { create(:customer) }
    let(:user) { create(:user, branch: customer.branch) }
    let!(:diagnosis1) { create(:diagnosis, customer: customer, user: user, diagnosed_on: 1.month.ago) }
    let!(:diagnosis2) { create(:diagnosis, customer: customer, user: user, diagnosed_on: Date.current) }

    it "recent は新しい順に返す" do
      expect(Diagnosis.recent.first).to eq(diagnosis2)
    end

    it "this_year は今年の診断のみ返す" do
      old_diagnosis = create(:diagnosis, customer: customer, user: user, diagnosed_on: 1.year.ago)
      expect(Diagnosis.this_year).to include(diagnosis1, diagnosis2)
      expect(Diagnosis.this_year).not_to include(old_diagnosis)
    end
  end

  describe "#display_date" do
    let(:customer) { create(:customer) }
    let(:user) { create(:user, branch: customer.branch) }

    it "日付をフォーマットして返す" do
      diagnosis = build(:diagnosis, customer: customer, user: user, diagnosed_on: Date.new(2024, 1, 15))
      expect(diagnosis.display_date).to eq("2024/01/15")
    end
  end

  describe "#document_type" do
    let(:customer) { create(:customer) }
    let(:user) { create(:user, branch: customer.branch) }
    let(:diagnosis) { create(:diagnosis, customer: customer, user: user) }

    it "添付なしの場合は nil" do
      expect(diagnosis.document_type).to be_nil
    end
  end
end
