class RecruitEmployeesController < ApplicationController
  include Cacas::Methods

  before_action :set_user, only: [:show, :edit, :destroy]

  def new
    @recruit_employee = cacas_prepare RecruitEmployee.new(user__employer_id: params[:employer_id])
  end

  def edit
  end

  def create
    @recruit_employee = cacas_prepare RecruitEmployee.new(user__employer_id: params[:employer_id])
    @recruit_employee.attributes = user_params

    respond_to do |format|
      if cacas_command(@recruit_employee).valid?
        format.html { redirect_to employer_url(@recruit_employee.user__employer_id), notice: 'Employee was successfully recruited.' }
      else
        format.html { render :new }
      end
    end
  end

  private

    def user_params
      params.require(:recruit_employee).permit(:user__redmine_login, :user__surname, :user__name,
                                               :user__redmine_mail, :user__phone, :user__is_blocked,
                                               :user__redmine_id, :user__redmine_password_hash,
                                               :user__groups, :user__employer_position, :user__employer_id)
    end
end
