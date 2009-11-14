class AddCheckedOutInfo < ActiveRecord::Migration
  def self.up
    change_table :documents do |t|
      t.integer :checked_out_by
      t.datetime :checked_out_at
    end
  end

  def self.down
    change_table :documents do |t|
      t.remove :checked_out_by
      t.remove :checked_out_at
    end
  end
end
