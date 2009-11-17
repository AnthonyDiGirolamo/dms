class Audit < ActiveRecord::Base
  belongs_to :document
  belongs_to :user
  belongs_to :share

  validates_presence_of :action
end
