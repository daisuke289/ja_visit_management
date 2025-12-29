# frozen_string_literal: true

require "rails_helper"

RSpec.describe VisitRecord, type: :model do
  let(:branch) { create(:branch) }
  let(:user) { create(:user, :branch_manager, branch: branch) }
  let(:customer) { create(:customer, branch: branch) }
  let(:visit_type) { create(:visit_type) }

  describe "associations" do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:visit_type) }
    it { is_expected.to belong_to(:visit_plan).optional }
    it { is_expected.to have_many(:actions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:visited_at) }
    it { is_expected.to validate_presence_of(:content) }

    it "validates content length minimum" do
      record = build(:visit_record, customer: customer, user: user, visit_type: visit_type,
                     content: "短い")
      expect(record).not_to be_valid
      expect(record.errors[:content]).to include("は50文字以上で入力してください")
    end

    it "allows content with 50 or more characters" do
      long_content = "あ" * 50
      record = build(:visit_record, customer: customer, user: user, visit_type: visit_type,
                     content: long_content)
      expect(record).to be_valid
    end
  end

  describe "callbacks" do
    describe "after_save :update_customer_last_visit_date" do
      it "updates customer last_visit_date" do
        visit_date = 1.day.ago
        create(:visit_record, customer: customer, user: user, visit_type: visit_type,
               visited_at: visit_date)

        expect(customer.reload.last_visit_date).to eq(visit_date.to_date)
      end
    end
  end
end
