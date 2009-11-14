class Share < ActiveRecord::Base
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  belongs_to :user
  belongs_to :document, :counter_cache => true

  validates_associated :owner
  validates_associated :user
  validates_associated :document

  validates_presence_of :can_read
  validates_presence_of :can_update
  validates_presence_of :can_checkout
end
