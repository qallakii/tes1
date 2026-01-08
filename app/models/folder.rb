class Folder < ApplicationRecord
  belongs_to :user
  has_many :cvs, dependent: :destroy
  has_many :share_links, dependent: :destroy

  validates :name, presence: true
end
