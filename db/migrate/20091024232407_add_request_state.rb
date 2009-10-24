class AddRequestState < ActiveRecord::Migration
  def self.up
    change_table :user_requests do |t|
      t.string :state, :default => 'pending'
    end
  end

  def self.down
    change_table :user_requests do |t|
      t.remove :state
    end
  end
end
