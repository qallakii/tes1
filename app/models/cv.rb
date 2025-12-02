class Cv < ApplicationRecord
  belongs_to :folder
  has_one_attached :file
  has_many :ratings, dependent: :destroy
end
