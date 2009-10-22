class CreateDepartments < ActiveRecord::Migration
  def self.up
    create_table :departments do |t|
      t.string :name

      t.timestamps
    end
    create_table :departments_users, :id => false do |t|
      t.integer :department_id
      t.integer :user_id
    end
    add_index :departments_users, :department_id
    add_index :departments_users, :user_id
  end

  def self.down
    drop_table :departments
    drop_table :departments_users
  end
end
