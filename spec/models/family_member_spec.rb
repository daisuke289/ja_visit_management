# frozen_string_literal: true

require "rails_helper"

RSpec.describe FamilyMember, type: :model do
  describe "バリデーション" do
    let(:customer) { create(:customer) }

    it "有効なファクトリ" do
      family_member = build(:family_member, customer: customer)
      expect(family_member).to be_valid
    end

    it "名前は必須" do
      family_member = build(:family_member, customer: customer, name: nil)
      expect(family_member).not_to be_valid
      expect(family_member.errors[:name]).to include("を入力してください")
    end

    it "続柄は必須" do
      family_member = build(:family_member, customer: customer, relationship: nil)
      expect(family_member).not_to be_valid
      expect(family_member.errors[:relationship]).to include("を入力してください")
    end

    it "続柄タイプは必須" do
      family_member = build(:family_member, customer: customer, relationship_type: nil)
      expect(family_member).not_to be_valid
      expect(family_member.errors[:relationship_type]).to include("を入力してください")
    end
  end

  describe "スコープ" do
    let(:customer) { create(:customer) }
    let!(:living_member) { create(:family_member, customer: customer, is_living: true) }
    let!(:deceased_member) { create(:family_member, customer: customer, is_living: false) }
    let!(:cohabitant) { create(:family_member, customer: customer, is_cohabitant: true) }

    it "living は存命者のみ返す" do
      expect(FamilyMember.living).to include(living_member, cohabitant)
      expect(FamilyMember.living).not_to include(deceased_member)
    end

    it "deceased は故人のみ返す" do
      expect(FamilyMember.deceased).to include(deceased_member)
      expect(FamilyMember.deceased).not_to include(living_member)
    end

    it "cohabitant は同居者のみ返す" do
      expect(FamilyMember.cohabitant).to include(cohabitant)
    end
  end

  describe "#age" do
    it "生年月日から年齢を計算する" do
      member = build(:family_member, birth_date: 30.years.ago)
      expect(member.age).to eq(30)
    end

    it "生年月日がnilの場合はnilを返す" do
      member = build(:family_member, birth_date: nil)
      expect(member.age).to be_nil
    end
  end

  describe "#display_name" do
    it "存命の場合は名前のみ返す" do
      member = build(:family_member, name: "山田太郎", is_living: true)
      expect(member.display_name).to eq("山田太郎")
    end

    it "故人の場合は（故人）を付ける" do
      member = build(:family_member, name: "山田太郎", is_living: false)
      expect(member.display_name).to eq("山田太郎（故人）")
    end
  end

  describe "#ja_customer" do
    let(:customer) { create(:customer) }
    let(:ja_customer) { create(:ja_customer, branch: customer.branch) }

    it "JA顧客番号から JaCustomer を取得できる" do
      member = create(:family_member, customer: customer, ja_customer_number: ja_customer.customer_number)
      expect(member.ja_customer).to eq(ja_customer)
    end

    it "JA顧客番号がない場合は nil を返す" do
      member = create(:family_member, customer: customer, ja_customer_number: nil)
      expect(member.ja_customer).to be_nil
    end
  end

  describe "#potential_heir?" do
    it "存命の配偶者は推定相続人" do
      member = build(:family_member, :spouse, is_living: true)
      expect(member.potential_heir?).to be true
    end

    it "存命の子は推定相続人" do
      member = build(:family_member, :child, is_living: true)
      expect(member.potential_heir?).to be true
    end

    it "故人は推定相続人ではない" do
      member = build(:family_member, :spouse, is_living: false)
      expect(member.potential_heir?).to be false
    end
  end

  describe "家系図関連" do
    let(:customer) { create(:customer) }
    let(:parent) { create(:family_member, :householder, customer: customer) }
    let(:child) { create(:family_member, :child, customer: customer, parent_member: parent) }

    it "親子関係が正しく設定される" do
      expect(child.parent_member).to eq(parent)
      expect(parent.children).to include(child)
    end
  end
end
