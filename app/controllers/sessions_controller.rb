class SessionsController < ApplicationController
  skip_before_action :require_login
  layout 'cover'
  
  # Show login form.
  #
  # GET /login
  def new
    redirect_to games_url if user_session.logged_in?
  end
  
  # Log user in.
  #
  # POST /login
  def create
    # Search for the user by the email address provided. The search is case-insensitive.
    # This query involves a full table scan, but is adequate for a small table.
    user = User.where('lower(email) = ?', params[:email].downcase).take
    
    # If the user is found and has supplied the correct password, log in
    # and redirect to games; otherwise, display error message.
    if user.try(:authenticate, params[:password])
      user_session.log_in user
      redirect_to games_url
    else
      flash.now[:danger] = "No user was found with that email address and password."
      render 'new'
    end
  end
  
  # Log user out.
  #
  # DELETE /logout
  def destroy
    user_session.log_out
    redirect_to root_url
  end
end
