class StaticPagesController < ApplicationController
  skip_before_action :require_login
  
  def home
    if user_session.logged_in?
      redirect_to games_url
    else
      render layout: 'cover'
    end
  end
end
