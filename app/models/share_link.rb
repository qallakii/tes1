class ShareLink < ApplicationRecord
  has_secure_token :token

  belongs_to :folder, optional: true
  belongs_to :user, optional: true

  has_many :share_link_folders, dependent: :destroy
  has_many :folders, through: :share_link_folders

  has_many :share_link_cvs, dependent: :destroy
  has_many :cvs, through: :share_link_cvs

  # Option C allowlist (only used when require_login = true)
  has_many :share_link_accesses, dependent: :destroy
  has_many :allowed_users, through: :share_link_accesses, source: :user

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def allow_preview?
    !!allow_preview
  end

  def allow_download?
    !!allow_download
  end

  def require_login?
    !!require_login
  end

  # All directly attached folders (old + new system)
  def all_folders
    (folders.to_a + (folder ? [folder] : [])).uniq
  end

  # Root folders only (used for recursive expansion)
  def root_folders
    all_folders
  end
end
