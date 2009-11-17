class Share < ActiveRecord::Base
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  belongs_to :user
  belongs_to :document, :counter_cache => true
  has_many :audits

  validates_associated :owner
  validates_associated :user
  validates_associated :document
end
