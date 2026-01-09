class ShareLink < ApplicationRecord
  belongs_to :folder

  has_many :share_link_cvs, dependent: :destroy
  has_many :cvs, through: :share_link_cvs

  before_create :generate_token
  before_create :set_expiration

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def limited_to_selected_files?
    share_link_cvs.exists?
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(10)
  end

  def set_expiration
    self.expires_at ||= 24.hours.from_now
  end
end
