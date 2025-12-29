# frozen_string_literal: true

require "rails_helper"

RSpec.describe Action, type: :model do
  let(:branch) { create(:branch) }
  let(:user) { create(:user, :branch_manager, branch: branch) }
  let(:customer) { create(:customer, branch: branch) }
  let(:visit_type) { create(:visit_type) }
  let(:visit_record) { create(:visit_record, customer: customer, user: user, visit_type: visit_type) }

  describe "associations" do
    it { is_expected.to belong_to(:visit_record) }
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:due_date) }
  end

  describe "scopes" do
    describe ".pending" do
      it "returns only pending actions" do
        pending_action = create(:action, customer: customer, user: user, visit_record: visit_record, status: :pending)
        completed_action = create(:action, customer: customer, user: user, visit_record: visit_record, status: :completed)

        expect(Action.pending).to include(pending_action)
        expect(Action.pending).not_to include(completed_action)
      end
    end

    describe ".overdue" do
      it "returns pending actions with past due dates" do
        overdue = create(:action, customer: customer, user: user, visit_record: visit_record,
                         status: :pending, due_date: 1.day.ago)
        future = create(:action, customer: customer, user: user, visit_record: visit_record,
                        status: :pending, due_date: 1.day.from_now)

        expect(Action.overdue).to include(overdue)
        expect(Action.overdue).not_to include(future)
      end
    end
  end

  describe "#overdue?" do
    it "returns true when pending and due date is past" do
      action = create(:action, customer: customer, user: user, visit_record: visit_record,
                      status: :pending, due_date: 1.day.ago)
      expect(action.overdue?).to be true
    end

    it "returns false when pending and due date is future" do
      action = create(:action, customer: customer, user: user, visit_record: visit_record,
                      status: :pending, due_date: 1.day.from_now)
      expect(action.overdue?).to be false
    end

    it "returns false when completed" do
      action = create(:action, customer: customer, user: user, visit_record: visit_record,
                      status: :completed, due_date: 1.day.ago)
      expect(action.overdue?).to be false
    end
  end
end
