json.array!(@users) do |user|
  json.extract! user, :id, :handle, :email
  json.url user_url(user, format: :json)
end
