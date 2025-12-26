# app/models/cv.rb
class Cv < ApplicationRecord
  belongs_to :user
  belongs_to :folder, optional: true
  has_one_attached :file
end
