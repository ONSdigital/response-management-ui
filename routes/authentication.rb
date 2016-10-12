NO_2FA_COOKIE = 'response_operations_no_2fa'.freeze
CLOCK_DRIFT   = 120
THIRTY_DAYS   = 60 * 60 * 24 * 30

# Only administrators and escalation team can access the management screens.
before '/manage*' do
  halt 403 unless authorised?('collect-admins') || authorised?('collect-general-escalate') || authorised?('collect-field-escalate')
end

get '/signin/?' do

  # CTPA-404 Always bypass the two factor authentication screen for 2016.
  response.set_cookie(NO_2FA_COOKIE, value: '1', max_age: THIRTY_DAYS.to_s)

  built  = settings.built
  commit = settings.commit

  # Display the correct built date and commit SHA when running locally.
  built = Date.today.strftime('%d_%b_%Y') if built == '01_Jan_1970'
  commit = `git rev-parse --short HEAD` if commit == 'commit'
  erb :signin, layout: :simple_layout, locals: { title: 'Sign In',
                                                 built: built,
                                                 commit: commit,
                                                 environment: settings.environment }
end

post '/signin/?' do
  ldap_connection = LDAPConnection.new(settings.ldap_directory_host,
                                       settings.ldap_directory_port,
                                       settings.ldap_directory_base,
                                       settings.ldap_groups,
                                       logger)

  if user = User.authenticate(ldap_connection, params) # rubocop:disable Lint/AssignmentInCondition
    session[:user] = user
    if request.cookies[NO_2FA_COOKIE]
      session[:valid_token] = true
      redirect_to_original_request
    else
      redirect '/signin/secondfactor'
    end
  else
    flash[:notice] = 'You could not be signed in. Did you enter the correct credentials?'
    redirect '/signin'
  end
end

get '/signin/secondfactor/?' do
  unless session[:user]
    flash[:notice] = 'Please sign in first.'
    redirect '/signin'
  end
  erb :second_factor, layout: :simple_layout, locals: { title: 'Sign In' }
end

post '/signin/secondfactor/?' do
  unless session[:user]
    flash[:notice] = 'Your session has expired. please sign in again.'
    redirect '/signin'
  end
  if session[:user].valid_code?(CLOCK_DRIFT, params)
    logger.info "'#{session[:user].display_name}' entered a valid 2FA token"
    if params[:rememberme]
      response.set_cookie(NO_2FA_COOKIE, value: '1', max_age: THIRTY_DAYS.to_s)
    else
      response.delete_cookie(NO_2FA_COOKIE)
    end
    session[:valid_token] = true
    redirect_to_original_request
  else
    logger.info "'#{session[:user].display_name}' entered an invalid 2FA token"
    flash[:notice] = 'The code you entered is incorrect. Please try again.'
    redirect '/signin/secondfactor'
  end
end

get '/signout' do
  logger.info "'#{session[:user].display_name}' signed out"
  session[:user] = nil
  session[:valid_token] = nil
  flash[:notice] = 'You have been signed out.'
  redirect '/'
end
