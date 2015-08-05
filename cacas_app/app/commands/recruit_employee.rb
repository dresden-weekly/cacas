class RecruitEmployee < Cacas::Command
  @event_name = "RecruitedEmployee"
  involved_models user: [ :surname, :name, :employer_id]

  validates_presence_of  :user__name, :user__surname

  # form_name 'User'
  def employer
    Employer.find self.user__employer_id
  end
end
