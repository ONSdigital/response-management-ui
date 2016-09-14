
# Get address by UPRN.
get '/addresses/:uprn' do |uprn|
  erb :address, locals: { uprn: uprn }
end

# Get address by postcode.
get '/addresses/postcode/:postcode' do |postcode|
  erb :address, locals: { uprn: nil, postcode: postcode }
end

# Get case.
get '/cases/:case_id' do |case_id|
  erb :case, locals: { case_id: case_id }
end

# Get case events for case.
get '/cases/:case_id/events' do |case_id|
  erb :events, locals: { case_id: case_id }
end

# Create case event.
post '/cases/:case_id/events' do |case_id|
  erb :new_event, locals: { case_id: case_id }
end

# Get case by UPRN.
get '/cases/uprn/:uprn' do |uprn|
  erb :cases, locals: { case_id: nil, uprn: uprn }
end

# List categories.
get '/categories' do
  erb :categories, locals: { role: params['role'] }
end

# List products.
get '/products' do
  erb :products, locals: { role: params['role'] }
end


# Get sample.
get '/samples/:sample_id' do |sample_id|
  erb :sample, locals: { sample_id: sample_id }
end

# Get survey.
get '/surveys/:survey_id' do |survey_id|
  erb :survey, locals: { survey_id: survey_id }
end

# List questionnaires for case.
get '/questionnaires/case/:case_id' do |case_id|
  erb :questionnaires, locals: { case_id: case_id }
end
