error 403 do
  erb :forbidden, locals: { title: '403 Forbidden' }
end

error 404 do
  erb :not_found, locals: { title: '404 Not Found' }
end
