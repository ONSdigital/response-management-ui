require 'yaml'

require_relative '../../../common/model/response_generator_instruction'

class ResponseGenerator

  # Load various settings from a configuration file.
  config = YAML.load_file(File.join(__dir__, '../../config/config.yml'))
  $respgen_service_host=config['response-gen-webservice']['host']
  $respgen_service_port=config['response-gen-webservice']['port']

  def self.read
    resp_body = JSON.parse(RestClient.get("http://#{$respgen_service_host}:#{$respgen_service_port}/responsegenerator"))

    instruction = ResponseGeneratorInstruction.new
    instruction.active = resp_body[ResponseGeneratorInstruction::ACTIVE_PARAM]
    instruction.responses_per_minute = resp_body[ResponseGeneratorInstruction::RESPONSES_PER_MIN_PARAM]
    instruction.filter = resp_body[ResponseGeneratorInstruction::FILTER_NAME_PARAM]
    instruction.run_until = resp_body[ResponseGeneratorInstruction::RUN_UNTIL_PARAM]
    instruction.filters =  resp_body[ResponseGeneratorInstruction::FILTERS_PARAM]
    instruction
  end

  def self.save(instruction)
    RestClient.post("http://#{$respgen_service_host}:#{$respgen_service_port}/responsegenerator",
                         instruction.to_json, content_type: :json, accept: :json)
  end

end
