class User < ApplicationRecord
  has_secure_password
  has_many :folders, dependent: :destroy
  has_many :cvs, dependent: :destroy
end
