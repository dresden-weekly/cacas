class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :process_after_jobs

  private

  def process_after_jobs
    Cacas::process_after_jobs
  end
end
