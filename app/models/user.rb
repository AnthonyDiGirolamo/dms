require 'digest/sha1'

class User < ActiveRecord::Base
  has_and_belongs_to_many :roles

  # has_role? simply needs to return true or false whether a user has a role or not.
  # It may be a good idea to have "admin" roles return true always
  def has_role?(role_in_question)
    @_list ||= self.roles.collect(&:name)
    return true if @_list.include?("admin")
    (@_list.include?(role_in_question.to_s) )
  end

  has_many :user_requests
  has_many :documents
  has_many :audits
  # Shares
  has_many :shares_by_me, :class_name => "Share", :foreign_key => "owner_id"
  has_many :shares_by_others, :class_name => "Share", :foreign_key => "user_id"
  # Shared Documents
  has_and_belongs_to_many :shared_documents_by_me, :class_name => "Document", :join_table => "shares", :foreign_key => "owner_id", :association_foreign_key => "document_id", :select => %{"documents".*, "shares".document_id AS id}
  has_and_belongs_to_many :shared_documents_by_others, :class_name => "Document", :join_table => "shares", :foreign_key => "user_id", :association_foreign_key => "document_id", :select => %{"documents".*, "shares".document_id AS id}
  has_and_belongs_to_many :departments

  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::StatefulRoles
  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..255
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_presence_of     :name
  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => false
  validates_length_of       :name,     :maximum => 255

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..255 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message


  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation, :time_zone


  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_in_state :first, :active, :conditions => {:login => login.downcase} # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  protected

  def make_activation_code
    # This is getting called twice somewhere. So,
    # check if it's new and only activate it once.
    if self.new_record?
      self.deleted_at = nil
      self.activation_code = self.class.make_token
    end
  end

end
