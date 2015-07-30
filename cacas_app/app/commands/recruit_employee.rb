class RecruitEmployee < Cacas::Command
  @event_name = "RecruitedEmployee"
  involved_models user: [:login, :surname, :name, :email, :phone,
                         :is_blocked, :redmine_id, :redmine_password_hash,
                         :groups, :employer_position, :employer_id]

  # form_name 'User'
  def employer
    Employer.find self.user__employer_id
  end
end
