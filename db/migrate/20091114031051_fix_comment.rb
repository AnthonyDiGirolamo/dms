class FixComment < ActiveRecord::Migration
  def self.up
    change_table :documents do |t|
      t.remove :comment
      t.text :comment
    end
  end

  def self.down
    change_table :documents do |t|
      t.remove :comment
      t.string :comment
    end
  end
end
