class AddUserQuota < ActiveRecord::Migration
  def self.up
  	add_column :users, :quota, :integer
  end

  def self.down
  	remove_column :users, :quota
  end
end
