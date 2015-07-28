class CreatedNewUser < Cacas::Command
  @event_name = "CreatedNewUser"
  involved_models user: [:username, :firstname, :lastname, :email]

  form_name 'User'
end
