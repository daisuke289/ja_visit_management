# app/models/visit_type.rb
class VisitType < ApplicationRecord
  # リレーション
  has_many :visit_plans, dependent: :restrict_with_error
  has_many :visit_records, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, uniqueness: true
  validates :display_order, presence: true

  # スコープ
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:display_order) }

  # メソッド
  def usage_count
    visit_records.count
  end

  # 相続・事業承継関連かどうか
  def inheritance_related?
    %w[相続発生前相談 相続発生後相談 事業承継相談 財産診断].include?(name)
  end
end
