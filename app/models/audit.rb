class Audit < ActiveRecord::Base
  belongs_to :document
  belongs_to :user

  validates_associated :document
  validates_associated :user

  validates_presence_of :action
end
