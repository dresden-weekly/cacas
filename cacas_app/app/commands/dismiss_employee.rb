class DismissEmployee < Cacas::Command
  @event_name = "DismissedEmployee"
  @actions = {user: :delete}

  involved_models user: [ :id, :surname, :name, :employer_id ]

  def employer
    Employer.find self.user__employer_id
  end
end
