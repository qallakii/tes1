class User < ApplicationRecord
  has_secure_password
  has_many :share_links, dependent: :destroy

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
end
