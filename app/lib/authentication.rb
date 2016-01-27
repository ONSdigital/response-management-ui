module Authentication
  def authenticate!
    unless session[:user] && session[:valid_token]
      session[:original_request] = request.path_info
      redirect '/signin'
    end
  end

  def authorised?
    session[:user].present? && session[:user].admin?
  end

  def redirect_to_original_request
    user = session[:user]
    flash[:notice] = "Welcome back #{user.display_name}."
    original_request = session[:original_request]
    session[:original_request] = nil
    redirect original_request
  end
end
