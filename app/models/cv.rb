class Cv < ApplicationRecord
  belongs_to :folder
  belongs_to :user, optional: true
  has_one_attached :file

  # ✅ auto title so uploads never fail
  before_validation :set_default_title, if: -> { title.blank? && file.attached? }

  validate :file_size_limit

  private

  def set_default_title
    # "MyFile.ext" -> "MyFile"
    self.title = file.filename.base.to_s
  end

  def file_size_limit
    return unless file.attached?
    if file.byte_size > 100.megabytes
      errors.add(:file, "must be smaller than 100MB")
    end
  end
end
