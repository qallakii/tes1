class ShareLink < ApplicationRecord
  has_secure_token :token
  has_secure_password validations: false

  belongs_to :folder, optional: true
  belongs_to :user, optional: true

  has_many :share_link_folders, dependent: :destroy
  has_many :folders, through: :share_link_folders

  has_many :share_link_cvs, dependent: :destroy
  has_many :cvs, through: :share_link_cvs
  has_many :share_link_accesses, dependent: :destroy
  has_many :allowed_users, through: :share_link_accesses, source: :user

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def all_folders
    (folders.to_a + (folder ? [ folder ] : [])).uniq
  end

  def password_protected?
    password_digest.present?
  end

  def disabled?
    respond_to?(:disabled) && !!self[:disabled]
  end

  def restricted_to_specific_people?
    share_link_accesses.exists?
  end

  def access_for(user)
    return nil unless user

    if association(:share_link_accesses).loaded?
      share_link_accesses.find { |access| access.user_id == user.id }
    else
      share_link_accesses.find_by(user_id: user.id)
    end
  end

  def permission_for(user)
    access_for(user)&.permission.presence || ShareLinkAccess::PERMISSION_VIEWER
  end

  def editor_for?(user)
    permission_for(user) == ShareLinkAccess::PERMISSION_EDITOR
  end

  def share_targets
    accesses =
      if association(:share_link_accesses).loaded?
        share_link_accesses
      else
        share_link_accesses.includes(:user)
      end

    entries = accesses.filter_map do |access|
      next unless access.user

      {
        kind: :user,
        label: access.user.email,
        name: access.user.name.presence,
        permission: access.permission.presence || ShareLinkAccess::PERMISSION_VIEWER
      }
    end

    return [ { kind: :public, label: "Anyone with the link", permission: ShareLinkAccess::PERMISSION_VIEWER } ] if entries.empty?

    entries.sort_by do |entry|
      [
        entry[:permission] == ShareLinkAccess::PERMISSION_EDITOR ? 0 : 1,
        entry[:label].to_s
      ]
    end
  end
end
