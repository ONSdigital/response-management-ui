
# Get address by UPRN.
get '/addresses/:uprn' do |uprn|
  erb :address, locals: { uprn: uprn }
end

# Get address by postcode.
get '/addresses/postcode/:postcode' do |postcode|
  erb :address, locals: { uprn: nil, postcode: postcode }
end

# Get actionplanmapping.
get '/actionplanmapping/:mapping_id' do |mapping_id|
  erb :actionplanmapping, locals: { mapping_id: mapping_id }
end

# Get actionplanmappings for casetype.
get '/actionplanmappings/casetype/:casetype_id' do |casetype_id|
  erb :actionplanmappings, locals: { casetype_id: casetype_id }
end

# Get casegroup
get '/casegroups/uprn/:uprn' do |uprn|
  erb :casegroup_uprn, locals: { uprn: uprn }
end

# Get casegroup
get '/casegroups/:casegroup_id' do |casegroup_id|
  erb :casegroup, locals: { casegroup_id: casegroup_id }
end

# Get cases by casgroup.
get '/cases/casegroup/:casegroup_id' do |casegroup_id|
  erb :cases, locals: { casegroup_id: casegroup_id }
end

# Get case.
get '/cases/:case_id' do |case_id|
  erb :case, locals: { case_id: case_id }
end

# Get case events for case.
get '/cases/:case_id/events' do |case_id|
  erb :events, locals: { case_id: case_id }
end

# Get casetypes.
get '/casetypes/:casetype_id' do |casetype_id|
  erb :casetypes, locals: { casetype_id: casetype_id }
end

# create case event.
post '/cases/:case_id/events' do |case_id|
  erb :new_event, locals: { case_id: case_id }
end

# List categories.
get '/categories' do
  erb :categories, locals: { role: params['role'], group: params['group'] }
end

# List categories.
get '/categories/:category_name' do |category_name|
  erb :category, locals: { category_name: category_name }
end

# Get sample.
get '/samples/:sample_id' do |sample_id|
  erb :sample, locals: { sample_id: sample_id }
end
