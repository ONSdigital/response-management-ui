require 'rack/deflater'

require_relative './routes/base'
require_relative './routes/regions_route'
require_relative './routes/lads_route'
require_relative './routes/msoas_route'
require_relative './routes/addresses_route'
require_relative './routes/cases_route'
require_relative './routes/questionnaires_route'
require_relative './routes/actions_route'
require_relative './routes/forms_route'
require_relative './routes/casetypes_route'
require_relative './routes/samples_route'
require_relative './routes/surveys_route'
require_relative './routes/actionplans_route'
require_relative './routes/events_route'
require_relative './routes/categories_route'

module BeyondMock
  class App < Sinatra::Application
    use Routes::Base
    use Routes::CaseFrameService
  end
end
