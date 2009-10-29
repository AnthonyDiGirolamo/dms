class AddCommentToDocument < ActiveRecord::Migration
  def self.up
    change_table :documents do |t|
      t.string :comment
    end
  end

  def self.down
    change_table :documents do |t|
      t.remove :comment
    end
  end
end
