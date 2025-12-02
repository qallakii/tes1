class ShareLink < ApplicationRecord
  belongs_to :folder
  before_create :generate_token
  before_create :set_expiration

  def expired?
    expires_at < Time.current
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(10)
  end

  def set_expiration
    # Expire in 24 hours by default
    self.expires_at ||= 24.hours.from_now
  end
end
