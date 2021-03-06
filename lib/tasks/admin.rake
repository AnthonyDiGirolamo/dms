task :admin => :environment do
  admin = User.find_by_login "admin"
  puts admin.inspect
  if admin
    puts admin.roles.inspect
    puts admin.departments.inspect
  end
end

task :make_admin => :environment do
  admin = User.find_by_login "admin"
  admin.destroy if admin

  Rails::Initializer.run do |config|
    config.action_mailer.raise_delivery_errors = false
  end

  puts "Creating admin..."
  admin = User.new
  admin.update_attribute :login, "admin"
  admin.update_attribute :name, "CSE545 Administrator"
  admin.update_attribute :crypted_password, "d53ee6e0fa9f651806112db7c4265408e586211e"
  admin.update_attribute :salt, "490c61b297b5d10c42030c51af08ad149c71b1be"
  admin.update_attribute :created_at, Time.now
  admin.update_attribute :updated_at, Time.now
  admin.update_attribute :remember_token, nil
  admin.update_attribute :remember_token_expires_at, nil
  admin.update_attribute :activation_code, nil
  admin.update_attribute :activated_at, Time.now
  admin.update_attribute :state, "active"
  admin.update_attribute :deleted_at, nil
  admin.update_attribute :quota, 52428800
  admin.update_attribute :time_zone, "Arizona"
  admin.update_attribute :email, "anthony.d@asu.edu"

  role = Role.find_by_name "administrator"

  admin.roles.delete_all
  admin.departments.delete_all
  admin.roles << role
  admin.save

  admin = User.find_by_login "admin"
  puts admin.inspect
  puts admin.roles.inspect
  puts admin.departments.inspect


  Rails::Initializer.run do |config|
    config.action_mailer.raise_delivery_errors = true
  end

end
