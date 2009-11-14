class CreateShares < ActiveRecord::Migration
  def self.up
    create_table :shares do |t|
      t.integer :owner_id
	  t.integer :user_id
	  t.integer :document_id
	  t.boolean :can_update, :default => false
	  t.boolean :can_checkout, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :shares
  end
end
