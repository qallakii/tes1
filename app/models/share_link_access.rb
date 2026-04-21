class ShareLinkAccess < ApplicationRecord
  PERMISSION_VIEWER = "viewer"
  PERMISSION_EDITOR = "editor"
  PERMISSIONS = [ PERMISSION_VIEWER, PERMISSION_EDITOR ].freeze

  belongs_to :share_link
  belongs_to :user

  before_validation :set_default_permission

  validates :permission, inclusion: { in: PERMISSIONS }
  validates :user_id, uniqueness: { scope: :share_link_id }

  def permission
    ensure_permission_attribute!
    self[:permission]
  end

  def permission=(value)
    ensure_permission_attribute!
    self[:permission] = value
  end

  def editor?
    permission == PERMISSION_EDITOR
  end

  def viewer?
    permission == PERMISSION_VIEWER
  end

  private

  def ensure_permission_attribute!
    return if has_attribute?(:permission)

    self.class.reset_column_information
  end

  def set_default_permission
    self.permission = PERMISSION_VIEWER if permission.blank?
  end
end
