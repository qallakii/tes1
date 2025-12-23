class Cv < ApplicationRecord
  belongs_to :user
  belongs_to :folder, optional: true
  has_one_attached :file

  validates :title, presence: true
end
