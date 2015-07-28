class UsersController < ApplicationController
  include Cacas::Methods

  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.all
  end

  def show
  end

  def new
    @user = CreateNewUser.new
  end

  def edit
  end

  def create
    @user = CreateNewUser.new(user_params)

    respond_to do |format|
      if cacas_command @user
        format.html { redirect_to users_url, notice: 'User was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
    end
  end

  private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      # params.require(:user).permit(:username, :firstname, :lastname, :email)
      params.require(:user).permit(:user__username, :user__firstname, :user__lastname, :user__email)
    end
end
