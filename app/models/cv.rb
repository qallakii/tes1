class Cv < ApplicationRecord
  belongs_to :folder
  belongs_to :user, optional: true
  has_one_attached :file

  # ✅ auto title so uploads never fail
  before_validation :set_default_title, if: -> { title.blank? && file.attached? }

  validate :pdf_only
  validate :file_size_limit

  private

  def set_default_title
    # "MyFile.pdf" -> "MyFile"
    self.title = file.filename.base.to_s
  end

  def pdf_only
    return unless file.attached?
    unless file.content_type == "application/pdf"
      errors.add(:file, "must be a PDF")
    end
  end

  def file_size_limit
    return unless file.attached?
    if file.byte_size > 10.megabytes
      errors.add(:file, "must be smaller than 10MB")
    end
  end
end
