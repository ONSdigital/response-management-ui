module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all the case types
      get '/casetypes' do
        erb :casetypes
      end

      # Get information for the specified case type
      get '/casetypes/:casetypeid' do
        erb :casetype, locals: { casetypeid: params['casetypeid'] }
      end

    end
  end
end
