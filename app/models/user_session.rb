class UserSession
  def initialize(session, cookies)
    @session = session
    @cookies = cookies
  end
  
  # Log user in.
  def log_in(user)
    raise TypeError unless user.is_a? User
    @session[:user_id] = user.id
    @cookies.signed[:user_id] = user.id # Used for Action Cable (and possibly routing)
    @user = user
  end
  
  # Log user out.
  def log_out
    @session[:user_id] = @user = nil
    @cookies.delete :user_id
  end
  
  # Get user currently logged in, returning nil if no user is logged in.
  def current_user
    user_id = @session[:user_id]
    @user ||= user_id && User.find(user_id)
  end
  
  # Determine whether user is logged in.
  def logged_in?
    !!@session[:user_id]
  end
end