class AddDocumentShareCount < ActiveRecord::Migration
  def self.up
    change_table :documents do |t|
      t.integer :shares_count, :default => 0
    end
  end

  def self.down
    change_table :documents do |t|
      t.remove :shares
    end
  end
end
