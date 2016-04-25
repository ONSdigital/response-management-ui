module BeyondMock
  module Routes
    class FollowUpService < Base

      # Get the follow-ups for the specified questionnaire.
      get '/FollowUpService/FollowUp/QuestionnaireId=:questionnaire_id' do
        erb :follow_ups
      end

      # Get the follow-ups for the specified address.
      get '/FollowUpService/FollowUp/AddressId=:address_id' do
        erb :follow_ups_with_address_notes
      end

      # Get the specified follow-up.
      get '/FollowUpService/FollowUp/CorrelationId=:follow_up_id' do
        erb :follow_up
      end

      # Create a new follow-up.
      post '/FollowUpService/FollowUp' do
        erb :new_follow_up
      end

      # Update an existing follow-up.
      put '/FollowUpService/FollowUp/:follow_up_id' do
        erb :edit_follow_up
      end

      # Delete (i.e. cancel or mark as reviewed) the specified follow-up.
      put '/FollowUpService/FollowUp/:follow_up_id' do
        erb :cancelled_follow_up
      end

      # Get information about the Redmine gateway for follow-ups.
      get '/FollowUpService/GatewayInfo' do
        erb :gateway
      end

      # Toggle the started/stopped state of the Redmine gateway for follow-ups.
      put '/FollowUpService/GatewayInfo' do
        erb :gateway_stopped
      end
    end
  end
end
