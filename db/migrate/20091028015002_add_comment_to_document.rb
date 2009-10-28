class AddCommentToDocument < ActiveRecord::Migration
  def self.up
    change_table :documents do |t|
      t.string :comment
      t.integer :checked_out_by_id
      t.string :real_mime_type
    end
  end

  def self.down
    change_table :documents do |t|
      t.remove :comment
      t.remove :checked_out_by_id
      t.remove :real_mime_type
    end
  end
end
