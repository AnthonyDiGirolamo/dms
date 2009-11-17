class AddAuditShare < ActiveRecord::Migration
  def self.up
    change_table :audits do |t|
      t.integer :share_id
    end
  end

  def self.down
    change_table :audits do |t|
      t.remove :share_id
    end
  end
end
