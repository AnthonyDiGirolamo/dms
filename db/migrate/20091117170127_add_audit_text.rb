class AddAuditText < ActiveRecord::Migration
  def self.up
    change_table :audits do |t|
      t.remove :action
      t.text :action
    end
  end

  def self.down
    change_table :audits do |t|
      t.remove :action
      t.string :action
    end
  end
end
