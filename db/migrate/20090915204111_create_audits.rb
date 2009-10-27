class CreateAudits < ActiveRecord::Migration
  def self.up
    create_table :audits do |t|
	  t.integer :document_id
	  t.integer :user_id
      t.string :action

      t.timestamps
    end
  end

  def self.down
    drop_table :audits
  end
end
