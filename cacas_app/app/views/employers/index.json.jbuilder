json.array!(@employers) do |employer|
  json.extract! employer, :id, :name, :contact_user, :is_client, :groups
  json.url employer_url(employer, format: :json)
end
