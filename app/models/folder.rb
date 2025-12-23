class Folder < ApplicationRecord
  belongs_to :user
  has_many :cvs, dependent: :destroy

  validates :name, presence: true
end
