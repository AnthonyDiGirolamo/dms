class AddUserQuota < ActiveRecord::Migration
  def self.up
  	add_column 'users', 'quota', :integer, :default => 50.megabyte
  end

  def self.down
  	remove_column 'users', 'quota'
  end
end
