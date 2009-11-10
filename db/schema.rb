# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091028015002) do

  create_table "audits", :force => true do |t|
    t.integer  "document_id"
    t.integer  "user_id"
    t.string   "action"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "departments", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "departments_users", :id => false, :force => true do |t|
    t.integer "department_id"
    t.integer "user_id"
  end

  add_index "departments_users", ["department_id"], :name => "index_departments_users_on_department_id"
  add_index "departments_users", ["user_id"], :name => "index_departments_users_on_user_id"

  create_table "documents", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.boolean  "checked_out",           :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_file_name"
    t.string   "document_content_type"
    t.integer  "document_file_size"
    t.integer  "document_updated_at"
    t.string   "comment"
    t.integer  "checked_out_by_id"
    t.string   "real_mime_type"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "shares", :force => true do |t|
    t.integer  "owner_id"
    t.integer  "user_id"
    t.integer  "document_id"
    t.boolean  "read?",       :default => false
    t.boolean  "update?",     :default => false
    t.boolean  "checkout?",   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_requests", :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.integer  "department_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",         :default => "pending"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "state",                                    :default => "passive"
    t.datetime "deleted_at"
    t.integer  "quota",                                    :default => 52428800
    t.string   "time_zone",                                :default => "Arizona"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
