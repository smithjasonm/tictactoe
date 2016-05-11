class StaticPagesController < ApplicationController
  def home
    if user_session.logged_in?
      redirect_to games_url
    else
      render layout: 'cover'
    end
  end

  def help
  end

  def about
  end
end
