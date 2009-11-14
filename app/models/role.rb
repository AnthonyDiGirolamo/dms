class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :requests

  validates_associated :users
  validates_associated :requests
end
