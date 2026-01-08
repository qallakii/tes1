class Cv < ApplicationRecord
  belongs_to :folder
  has_one_attached :file

  validates :title, presence: true
  validate :pdf_only
  validate :file_size_limit

  private

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
