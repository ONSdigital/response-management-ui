
# List actions.
get '/actions' do
  erb :actions, locals: { actiontype: params['actiontype'] }
end

# List actions for case.
get '/actions/case/:case_id' do |case_id|
  erb :case_actions, locals: { case_id: case_id }
end

# Update action feedback.
put '/actions/:action_id/feedback' do
  erb :action_feedback, locals: { action_id: action_id }
end
