class RecruitEmployeesController < ApplicationController
  include Cacas::Methods

  before_action :set_user, only: [:show, :edit, :destroy]

  def new
    @recruit_employee = RecruitEmployee.new user__employer_id: params[:employer_id]
    # @employer = Employer.find params[:employer_id]
  end

  def edit
  end

  def create
    @recruit_employee = RecruitEmployee.new(user_params)

    respond_to do |format|
      if cacas_command @recruit_employee
        format.html { redirect_to users_url, notice: 'User was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  private

    def set_user
      @recruit_employee = User.find(params[:id])
    end

    def user_params
      # params.require(:user).permit(:username, :firstname, :lastname, :email)
      params.require(:recruit_employee).permit(:user__login, :user__surname, :user__name,
                                               :user__email, :user__phone, :user__is_blocked,
                                               :user__redmine_id, :user__redmine_password_hash,
                                               :user__groups, :user__employer_position, :user__employer_id)
    end
end
