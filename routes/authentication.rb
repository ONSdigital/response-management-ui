NO_2FA_COOKIE = 'response_operations_no_2fa'.freeze
CLOCK_DRIFT   = 120
THIRTY_DAYS   = 60 * 60 * 24 * 30

auth_logger   = Syslog::Logger.new(PROGRAM, Syslog::LOG_AUTHPRIV)

helpers do
  def user_role
    session[:user].groups.join(',')
  end
end

# Only administrators and escalation team can access the management screens.
before '/manage*' do
  halt 403 unless authorised?('collect-admins') || authorised?('collect-general-escalate') || authorised?('collect-field-escalate')
end

get '/signin/?' do
  erb :signin, layout: :simple_layout, locals: { title: 'Sign In' }
end

post '/signin/?' do
  user = User.authenticate(settings.client_user, settings.client_password, settings.oauth_server, params)
  if user
    session[:valid_token] = true
    session[:user] = user
    session[:display_name] = params['username'].split('@')[0].tr('.', ' ').gsub(/\b\w/, &:capitalize)
    auth_logger.info "#{session[:display_name]} signed in"
    redirect_to_original_request
  else
    flash[:notice] = 'You could not be signed in. Did you enter the correct credentials?'
    redirect '/signin'
  end
end

get '/signout' do
  auth_logger.info "#{session[:display_name]} signed out"
  session[:user] = nil
  session[:valid_token] = nil
  flash[:notice] = 'You have been signed out.'
  redirect '/'
end
