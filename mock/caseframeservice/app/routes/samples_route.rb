module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all samples
      get '/samples' do
        erb :samples
      end

      # get information for the specified sample
      get '/samples/:sampleid' do
        erb :sample, locals: { sampleid: params['sampleid'] }
      end

    end
  end
end
