class StaticPagesController < ApplicationController
  def home
    render layout: 'cover'
  end

  def help
  end

  def about
  end
end
