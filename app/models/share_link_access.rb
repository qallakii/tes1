class ShareLinkAccess < ApplicationRecord
  belongs_to :share_link
  belongs_to :user

  validates :user_id, uniqueness: { scope: :share_link_id }
end
