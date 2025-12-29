# app/models/family_member.rb
class FamilyMember < ApplicationRecord
  # リレーション
  belongs_to :customer
  belongs_to :parent_member, class_name: "FamilyMember", optional: true
  belongs_to :spouse_member, class_name: "FamilyMember", optional: true

  has_many :children, class_name: "FamilyMember", foreign_key: "parent_member_id", dependent: :nullify

  # 続柄タイプ
  enum :relationship_type, {
    householder: 0,   # 世帯主
    spouse: 1,        # 配偶者
    child: 2,         # 子
    grandchild: 3,    # 孫
    parent: 4,        # 親
    sibling: 5,       # 兄弟姉妹
    nephew_niece: 6,  # 甥姪
    other: 99         # その他
  }

  # 婚姻状態
  enum :marriage_status, {
    unmarried: 0,     # 未婚
    married: 1,       # 婚姻中
    divorced: 2,      # 離婚
    widowed: 3        # 死別
  }, prefix: true

  # バリデーション
  validates :name, presence: true
  validates :relationship, presence: true
  validates :relationship_type, presence: true

  # スコープ
  scope :living, -> { where(is_living: true) }
  scope :deceased, -> { where(is_living: false) }
  scope :cohabitant, -> { where(is_cohabitant: true) }
  scope :by_generation, ->(gen) { where(generation: gen) }
  scope :ordered_by_generation, -> { order(generation: :desc, birth_date: :asc) }

  # メソッド
  def age
    return nil unless birth_date
    today = Date.current
    age = today.year - birth_date.year
    age -= 1 if today < birth_date + age.years
    age
  end

  def display_name
    suffix = is_living? ? "" : "（故人）"
    "#{name}#{suffix}"
  end

  def full_info
    parts = [ name ]
    parts << "(#{age}歳)" if age
    parts << relationship
    parts << "【同居】" if is_cohabitant?
    parts << "【JA取引有】" if ja_customer.present?
    parts.join(" ")
  end

  # JA顧客との紐付け
  def ja_customer
    return nil if ja_customer_number.blank?
    JaCustomer.find_by(customer_number: ja_customer_number)
  end

  def has_ja_transaction?
    ja_customer.present?
  end

  # 家系図用メソッド
  def descendants
    result = []
    children.each do |child|
      result << child
      result.concat(child.descendants)
    end
    result
  end

  def ancestors
    result = []
    if parent_member
      result << parent_member
      result.concat(parent_member.ancestors)
    end
    result
  end

  # 推定相続人判定（簡易版）
  def potential_heir?
    return false unless is_living?
    %w[spouse child grandchild parent sibling nephew_niece].include?(relationship_type)
  end

  class << self
    # 家系図ツリー構築
    def build_tree(customer)
      householder = customer.family_members.find_by(relationship_type: :householder)
      return [] unless householder

      build_node(householder)
    end

    private

    def build_node(member)
      {
        id: member.id,
        name: member.display_name,
        relationship: member.relationship,
        age: member.age,
        is_living: member.is_living?,
        has_ja_transaction: member.has_ja_transaction?,
        spouse: member.spouse_member ? build_node(member.spouse_member) : nil,
        children: member.children.map { |c| build_node(c) }
      }
    end
  end
end
