# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_dms_session',
  :secret      => '64730fbbc31280af56387d7c8a4f5e2beaec4fa43c9259b9f9ede580f61c02bb94ccbebda086b0dde01697eb5d6eaa758495b9fe7fa8eb1543f7f36a8a2a3520'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
