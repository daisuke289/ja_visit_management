# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer, type: :model do
  let(:branch) { create(:branch) }

  describe "associations" do
    it { is_expected.to belong_to(:branch) }
    it { is_expected.to have_many(:visit_plans).dependent(:destroy) }
    it { is_expected.to have_many(:visit_records).dependent(:destroy) }
    it { is_expected.to have_many(:actions).dependent(:destroy) }
    it { is_expected.to have_many(:family_members).dependent(:destroy) }
    it { is_expected.to have_many(:diagnoses).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:branch) }
  end

  describe "scopes" do
    describe ".unvisited_for" do
      it "returns customers not visited within days" do
        visited_recently = create(:customer, branch: branch, last_visit_date: 10.days.ago)
        not_visited = create(:customer, branch: branch, last_visit_date: 40.days.ago)
        never_visited = create(:customer, branch: branch, last_visit_date: nil)

        result = Customer.unvisited_for(30)
        expect(result).to include(not_visited, never_visited)
        expect(result).not_to include(visited_recently)
      end
    end

    describe ".by_branch" do
      it "returns customers for the given branch" do
        other_branch = create(:branch)
        customer1 = create(:customer, branch: branch)
        customer2 = create(:customer, branch: other_branch)

        result = Customer.by_branch(branch.id)
        expect(result).to include(customer1)
        expect(result).not_to include(customer2)
      end
    end
  end

  describe "#visit_status" do
    it "returns :good when visited within 14 days" do
      customer = create(:customer, branch: branch, last_visit_date: 7.days.ago)
      expect(customer.visit_status).to eq(:good)
    end

    it "returns :warning when visited between 14 and 30 days" do
      customer = create(:customer, branch: branch, last_visit_date: 20.days.ago)
      expect(customer.visit_status).to eq(:warning)
    end

    it "returns :overdue when visited more than 30 days ago" do
      customer = create(:customer, branch: branch, last_visit_date: 40.days.ago)
      expect(customer.visit_status).to eq(:overdue)
    end

    it "returns :never when never visited" do
      customer = create(:customer, branch: branch, last_visit_date: nil)
      expect(customer.visit_status).to eq(:never)
    end
  end

  describe "#days_since_last_visit" do
    it "returns nil when never visited" do
      customer = create(:customer, branch: branch, last_visit_date: nil)
      expect(customer.days_since_last_visit).to be_nil
    end

    it "returns the number of days since last visit" do
      customer = create(:customer, branch: branch, last_visit_date: 10.days.ago)
      expect(customer.days_since_last_visit).to eq(10)
    end
  end

  describe "#pending_actions" do
    it "returns pending actions ordered by due date" do
      customer = create(:customer, branch: branch)
      user = create(:user, :branch_manager, branch: branch)
      visit_type = create(:visit_type)
      visit_record = create(:visit_record, customer: customer, user: user, visit_type: visit_type)

      action1 = create(:action, customer: customer, user: user, visit_record: visit_record,
                       due_date: 5.days.from_now, status: :pending)
      action2 = create(:action, customer: customer, user: user, visit_record: visit_record,
                       due_date: 2.days.from_now, status: :pending)
      completed_action = create(:action, customer: customer, user: user, visit_record: visit_record,
                                due_date: 1.day.from_now, status: :completed)

      result = customer.pending_actions
      expect(result).to eq([ action2, action1 ])
      expect(result).not_to include(completed_action)
    end
  end
end
