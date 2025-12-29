# frozen_string_literal: true

require "rails_helper"

RSpec.describe VisitPlan, type: :model do
  let(:branch) { create(:branch) }
  let(:user) { create(:user, :branch_manager, branch: branch) }
  let(:customer) { create(:customer, branch: branch) }
  let(:visit_type) { create(:visit_type) }

  describe "associations" do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:visit_type) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:planned_date) }
  end

  describe "scopes" do
    describe ".scheduled" do
      it "returns only scheduled plans" do
        scheduled = create(:visit_plan, customer: customer, user: user, visit_type: visit_type, status: :scheduled)
        completed = create(:visit_plan, customer: customer, user: user, visit_type: visit_type, status: :completed)
        cancelled = create(:visit_plan, customer: customer, user: user, visit_type: visit_type, status: :cancelled)

        expect(VisitPlan.scheduled).to include(scheduled)
        expect(VisitPlan.scheduled).not_to include(completed, cancelled)
      end
    end

    describe ".overdue" do
      it "returns scheduled plans with past dates" do
        overdue = create(:visit_plan, customer: customer, user: user, visit_type: visit_type,
                         status: :scheduled, planned_date: 1.day.ago)
        future = create(:visit_plan, customer: customer, user: user, visit_type: visit_type,
                        status: :scheduled, planned_date: 1.day.from_now)
        completed_overdue = create(:visit_plan, customer: customer, user: user, visit_type: visit_type,
                                   status: :completed, planned_date: 1.day.ago)

        expect(VisitPlan.overdue).to include(overdue)
        expect(VisitPlan.overdue).not_to include(future, completed_overdue)
      end
    end

    describe ".upcoming" do
      it "returns scheduled plans with future dates ordered by date" do
        plan1 = create(:visit_plan, customer: customer, user: user, visit_type: visit_type,
                       status: :scheduled, planned_date: 5.days.from_now)
        plan2 = create(:visit_plan, customer: customer, user: user, visit_type: visit_type,
                       status: :scheduled, planned_date: 2.days.from_now)
        past = create(:visit_plan, customer: customer, user: user, visit_type: visit_type,
                      status: :scheduled, planned_date: 1.day.ago)

        result = VisitPlan.upcoming
        expect(result.first).to eq(plan2)
        expect(result.second).to eq(plan1)
        expect(result).not_to include(past)
      end
    end
  end

  describe "#overdue?" do
    it "returns true when scheduled and date is past" do
      plan = create(:visit_plan, customer: customer, user: user, visit_type: visit_type,
                    status: :scheduled, planned_date: 1.day.ago)
      expect(plan.overdue?).to be true
    end

    it "returns false when scheduled and date is future" do
      plan = create(:visit_plan, customer: customer, user: user, visit_type: visit_type,
                    status: :scheduled, planned_date: 1.day.from_now)
      expect(plan.overdue?).to be false
    end

    it "returns false when completed" do
      plan = create(:visit_plan, customer: customer, user: user, visit_type: visit_type,
                    status: :completed, planned_date: 1.day.ago)
      expect(plan.overdue?).to be false
    end
  end
end
