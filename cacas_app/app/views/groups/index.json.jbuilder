json.array!(@groups) do |group|
  json.extract! group, :id, :name, :every_employee, :employer_id, :redmine_id, :users
  json.url group_url(group, format: :json)
end
