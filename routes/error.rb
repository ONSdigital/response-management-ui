# frozen_string_literal: true

error 403 do
  erb :forbidden, locals: { title: '403 Forbidden' }
end

error 404 do
  erb :not_found, locals: { title: '404 Not Found' }
end

error 500 do
  erb :internal_server_error, { title: '500 Internal Server Error' }
end
