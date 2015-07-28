json.array!(@users) do |user|
  json.extract! user, :id, :login, :surname, :name, :email, :phone, :is_blocked, :redmine_id, :redmine_password_hash, :groups, :employer_position
  json.url user_url(user, format: :json)
end
