json.suggestions do
  json.array! @friends.map{|f| f.email}
end