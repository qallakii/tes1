class Rating < ApplicationRecord
  belongs_to :cv
  belongs_to :user # Add this relation

  validates :stars, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :cv_id, message: "has already rated this CV" }
end
