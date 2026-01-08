class ShareLink < ApplicationRecord
  belongs_to :folder

  before_create :generate_token

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end
end
