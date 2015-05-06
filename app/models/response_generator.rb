require 'pg'
require 'yaml'

class ResponseGenerator

  attr_accessor :active
  attr_accessor :responses_per_minute
  attr_accessor :filter
  attr_accessor :run_until
  attr_accessor :filter_names

  def initialize
    @config = YAML.load_file('config/config.yml')
    @connection = PG.connect(host: @config['database']['host'], dbname: @config['database']['name'],
                             user: @config['database']['user'], password: @config['database']['password'])
    result = configuration
    @active = result.first['active']
    @responses_per_minute = result.first['responses_per_minute']
    @filter = result.first['filter']
    @run_until = result.first['run_until']
    @filter_names = filter_names
  end

  def save!
    @connection.prepare('statement', "UPDATE input_data.responsegenerator SET active = '#{@active}',
    responses_per_minute = #{@responses_per_minute}, filter = '#{@filter}',  run_until = '#{@run_until}'
    WHERE id = 1")
    result = @connection.exec_prepared('statement')
    # TODO: save any new filter
  end

  def active?
    @active
  end

  def configuration
    result = @connection.exec("SELECT responsegenerator.active, responsegenerator.responses_per_minute,
    responsegenerator.filter, responsegenerator.run_until
    FROM input_data.responsegenerator WHERE responsegenerator.id = 1")
  end

  def filter_names
    result = @connection.exec("SELECT responsegeneratorfilter.name, responsegeneratorfilter.where_sql
    FROM input_data.responsegeneratorfilter")
  end

end
