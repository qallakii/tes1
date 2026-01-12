class ShareLinkFolder < ApplicationRecord
  belongs_to :share_link
  belongs_to :folder
end
