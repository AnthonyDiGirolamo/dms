class UserRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  belongs_to :department

  validates_associated :user
  validates_associated :role
  validates_associated :department
end
