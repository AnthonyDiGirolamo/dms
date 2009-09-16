class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.integer :user_id
      t.string :name
      t.string :content_type
      t.binary :data
      t.integer :size
      t.boolean :checked_out, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :documents
  end
end
