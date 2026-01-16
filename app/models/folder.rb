class Folder < ApplicationRecord
  belongs_to :user
  has_many :cvs, dependent: :destroy

  has_many :share_link_folders, dependent: :destroy
  has_many :share_links, through: :share_link_folders
end
