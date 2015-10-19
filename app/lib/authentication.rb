module Authentication
  def authenticate!
    unless session[:user] && session[:valid_token]
      session[:original_request] = request.path_info
      redirect '/signin'
    end
  end
end
