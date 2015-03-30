json.array!(@friends) do |friend|
  json.extract! friend, :id, :email, :name
end