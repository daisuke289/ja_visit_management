# app/models/diagnosis.rb
class Diagnosis < ApplicationRecord
  # リレーション
  belongs_to :customer
  belongs_to :user

  has_one_attached :document

  # バリデーション
  validates :diagnosed_on, presence: true
  validates :title, presence: true
  validate :acceptable_document

  # スコープ
  scope :by_branch, ->(branch_id) {
    joins(:customer).where(customers: { branch_id: branch_id })
  }
  scope :recent, -> { order(diagnosed_on: :desc) }
  scope :this_year, -> {
    where(diagnosed_on: Date.current.beginning_of_year..Date.current.end_of_year)
  }

  # メソッド
  def display_date
    diagnosed_on.strftime("%Y/%m/%d")
  end

  def document_type
    return nil unless document.attached?

    case document.content_type
    when "application/pdf"
      :pdf
    when "application/vnd.openxmlformats-officedocument.presentationml.presentation",
         "application/vnd.ms-powerpoint"
      :pptx
    else
      :other
    end
  end

  def document_icon
    case document_type
    when :pdf then "📄"
    when :pptx then "📊"
    else "📎"
    end
  end

  private

  def acceptable_document
    return unless document.attached?

    acceptable_types = [
      "application/pdf",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      "application/vnd.ms-powerpoint"
    ]

    unless acceptable_types.include?(document.content_type)
      errors.add(:document, "はPDFまたはPowerPointファイルのみアップロード可能です")
    end

    if document.byte_size > 50.megabytes
      errors.add(:document, "は50MB以下にしてください")
    end
  end
end
