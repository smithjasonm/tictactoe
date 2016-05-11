class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_action :require_login
  helper_method :user_session
  
  def user_session
    @user_session ||= UserSession.new(session)
  end
  
  private
    
    # Redirect users who are not logged in to login page.
    def require_login
      unless user_session.logged_in?
        flash[:danger] = "Please log in to continue."
        redirect_to login_url
      end
    end
end
