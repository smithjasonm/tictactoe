class SessionsController < ApplicationController
  skip_before_action :require_login
  layout 'cover'
  
  def new
    redirect_to games_url if user_session.logged_in?
  end
  
  def create
    # This query involves a full table scan, but should be adequate for a small table.
    user = User.where('lower(email) = ?', params[:email].downcase).take
    if user.try(:authenticate, params[:password])
      user_session.log_in user
      redirect_to games_url
    else
      flash.now[:danger] = "No user was found with that email address and password."
      render 'new'
    end
  end
  
  def destroy
    user_session.log_out
    redirect_to root_url
  end
end
