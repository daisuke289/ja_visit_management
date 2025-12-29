# frozen_string_literal: true

require "rails_helper"

RSpec.describe FamilyMemberPolicy, type: :policy do
  let(:branch) { create(:branch) }
  let(:other_branch) { create(:branch) }
  let(:customer) { create(:customer, branch: branch) }
  let(:family_member) { create(:family_member, customer: customer) }

  describe "支店長" do
    let(:user) { create(:user, :branch_manager, branch: branch) }
    let(:policy) { described_class.new(user, family_member) }

    context "自支店の顧客" do
      it "閲覧可能" do
        expect(policy.index?).to be true
        expect(policy.show?).to be true
      end

      it "編集可能" do
        expect(policy.create?).to be true
        expect(policy.update?).to be true
        expect(policy.destroy?).to be true
      end
    end

    context "他支店の顧客" do
      let(:other_customer) { create(:customer, branch: other_branch) }
      let(:other_member) { create(:family_member, customer: other_customer) }
      let(:policy) { described_class.new(user, other_member) }

      it "閲覧不可" do
        expect(policy.index?).to be false
        expect(policy.show?).to be false
      end

      it "編集不可" do
        expect(policy.create?).to be false
        expect(policy.update?).to be false
        expect(policy.destroy?).to be false
      end
    end
  end

  describe "本店管理者" do
    let(:user) { create(:user, :admin) }
    let(:policy) { described_class.new(user, family_member) }

    it "全支店の顧客を閲覧可能" do
      expect(policy.index?).to be true
      expect(policy.show?).to be true
    end

    it "全支店の顧客を編集可能" do
      expect(policy.create?).to be true
      expect(policy.update?).to be true
      expect(policy.destroy?).to be true
    end
  end
end
