class Department < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :documents, :class_name => "Document", :finder_sql => %{SELECT "documents".* FROM "users" INNER JOIN "departments_users" ON "departments_users".user_id = "users".id INNER JOIN "departments" on "departments_users".department_id = "departments".id INNER JOIN "documents" ON "users".id = "documents".user_id  WHERE "departments".id ='1';}
end
