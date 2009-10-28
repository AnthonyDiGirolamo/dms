class AddFileToDocument < ActiveRecord::Migration
  def self.up
    change_table :documents do |t|
      t.remove :data
      t.remove :content_type
      t.remove :size
      t.string :document_file_name
      t.string :document_content_type
      t.integer :document_file_size
      t.integer :document_updated_at
    end
  end

  def self.down
    change_table :documents do |t|
      t.binary :data
      t.string :content_type
      t.integer :size
      t.remove :document_file_name
      t.remove :document_content_type
      t.remove :document_file_size
      t.remove :document_updated_at
    end
  end
end
