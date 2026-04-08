class User < ApplicationRecord
  has_secure_password
  has_many :share_links, dependent: :destroy
  has_many :share_link_accesses, dependent: :destroy
  has_many :accessible_share_links, through: :share_link_accesses, source: :share_link

  has_many :folders, dependent: :destroy
  has_many :cvs, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  validates :name, length: { maximum: 50 }, allow_nil: true

  # helper to safely get first name or fallback to email
  def first_name
    if name.present?
      name.split(" ").first
    else
      email.split("@").first
    end
  end

  def suspended?
    respond_to?(:suspended) && !!self[:suspended]
  end

  def force_password_change?
    respond_to?(:force_password_change) && !!self[:force_password_change]
  end

  def generate_password_reset_token!
    update!(
      reset_password_token: SecureRandom.urlsafe_base64(24),
      reset_password_sent_at: Time.current
    )
    reset_password_token
  end

  def clear_password_reset_token!
    update!(reset_password_token: nil, reset_password_sent_at: nil)
  end

  def clear_password_change_requirement!
    update!(force_password_change: false)
  end

  def password_reset_period_valid?
    reset_password_sent_at.present? && reset_password_sent_at >= 7.days.ago
  end
end
