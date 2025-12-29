# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # 権限
  enum :role, {
    branch_manager: 0,  # 支店長
    admin: 1,           # 本店管理者
    system_admin: 2     # システム管理者
  }

  # リレーション
  belongs_to :branch, optional: true
  has_many :visit_plans, dependent: :restrict_with_error
  has_many :visit_records, dependent: :restrict_with_error
  has_many :actions, dependent: :restrict_with_error
  has_many :diagnoses, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true
  validates :role, presence: true
  validates :branch, presence: true, if: :branch_manager?

  # スコープ
  scope :by_branch, ->(branch_id) { where(branch_id: branch_id) }

  # メソッド
  def can_access_all_branches?
    admin? || system_admin?
  end

  def accessible_branch_ids
    if can_access_all_branches?
      Branch.pluck(:id)
    else
      [ branch_id ].compact
    end
  end
end
