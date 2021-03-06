class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
  
    @body[:url]  = "https://129.219.33.6/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "https://129.219.33.6/"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "adigiro@asu.edu"
      @subject     = "Document Management System - "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
