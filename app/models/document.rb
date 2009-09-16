class Document < ActiveRecord::Base
	belongs_to :user
	has_many :audits
	has_many :shares
end
