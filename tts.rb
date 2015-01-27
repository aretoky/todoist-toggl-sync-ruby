require 'faraday_middleware'
require 'awesome_print'
require 'time'
require 'yaml'
require 'active_support'
require 'active_support/core_ext'

require_relative 'lib/todoist_api'
require_relative 'lib/toggl_api'
require_relative 'lib/syncer'


def run_sync(todoist_token, toggl_token)
  s = Syncer.new
  s.set_credentials(todoist_token, toggl_token)
  s.sync
end

config = YAML.load_file('config.yml')
run_sync(config['todoist_token'], config['toggl_token'])

