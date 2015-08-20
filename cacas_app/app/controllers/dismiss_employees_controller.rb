class DismissEmployeesController < ApplicationController
  include Cacas::Methods

  def new
    @dismiss_employee = cacas_prepare DismissEmployee.new(user__id: params[:user__id])
  end

  def create
    @dismiss_employee = cacas_prepare DismissEmployee.new(user__id: dismiss_employee_params[:user__id])

    respond_to do |format|
      if cacas_command(@dismiss_employee).valid?
        format.html { redirect_to employer_url(@dismiss_employee.user__employer_id), notice: 'Employee was successfully dismissed.' }
      else
        format.html { render :new }
      end
    end
  end

  private

  def dismiss_employee_params
    params.require(:dismiss_employee).permit(:user__id)
  end
end
