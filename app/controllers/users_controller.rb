class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user, only: [:edit, :update, :destroy]
  skip_before_action :require_login, only: [:new, :create]

  # GET /users
  def index
  end

  # GET /users/1
  # GET /users/1.json
  def show
    current_user = user_session.current_user
    @pair_record = current_user.game_record(@user) unless @user.id == current_user.id
    @full_record = @user.game_record
  end

  # GET /users/new
  def new
    if user_session.logged_in?
      redirect_to games_url
    else
      @user = User.new
      render layout: 'cover'
    end
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        user_session.log_in @user
        format.any(:html, :js) { redirect_to games_url }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, layout: 'cover' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.any(:html, :js) do
          flash[:success] = "Your settings have been updated."
          redirect_to @user
        end
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    user_session.log_out
    respond_to do |format|
      format.html do
        flash[:success] = "Your account has been deleted."
        redirect_to root_url
      end
      format.json { head :no_content }
    end
  end
  
  # Search for a user by handle or by email address.
  #
  # GET /users/search
  # GET /users/search.json
  def search
    query = params[:query]
    
    # If the query includes an "@," search by email address, otherwise search by handle.
    # The search is case-insensitive. Since the handles and email addresses are stored
    # in the database in their original forms, without first being converted to
    # lowercase, it is necessary to convert them to lowercase during the search.
    # This involves full-table scans, which would be inefficient for larger tables,
    # but are of no consequence to this application.
    if query.include? '@'
      @user = User.find_by 'LOWER(email) = LOWER(?)', query
    else
      @user = User.find_by 'LOWER(handle) = LOWER(?)', query
    end
    
    respond_to do |format|
      if @user
        format.html { redirect_to @user }
        format.json { render :show }
      else
        format.html do
          @user_not_found = true
          render :index
        end
        format.json { head :not_found }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:handle, :email, :password, :password_confirmation)
    end
    
    # Allow access only to the current user.
    def authorize_user
      head :forbidden unless @user.id == user_session.current_user.id
    end
end
