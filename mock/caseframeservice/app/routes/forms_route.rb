module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all form types
      get '/forms' do
        erb :forms
      end

      # Get information for the specified form type
      get '/forms/:formtype' do
        erb :form, locals: { formtype: params['formtype'] }
      end

    end
  end
end
