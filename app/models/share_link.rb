class ShareLink < ApplicationRecord
  has_secure_token :token

  belongs_to :folder, optional: true
  belongs_to :user, optional: true

  has_many :share_link_folders, dependent: :destroy
  has_many :folders, through: :share_link_folders

  has_many :share_link_cvs, dependent: :destroy
  has_many :cvs, through: :share_link_cvs

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def all_folders
    (folders.to_a + (folder ? [folder] : [])).uniq
  end
end
