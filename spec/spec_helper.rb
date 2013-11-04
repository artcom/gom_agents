require 'rubygems'
require 'bundler/setup'
require 'chromatic'

# COVERAGE env variable controls if coverage data is collected and the output
# format at the same time.
# COVERAGE values:
#  * html -> uses default html formatter
#  * rcov -> uses rcov-formatter (mainly useful for jenkins)
if ENV['COVERAGE']
  puts ' * Performing coverage via simplecov'.yellow
  require 'simplecov'
  require 'simplecov-rcov'
  SIMPLECOV_FORMATTERS = {
    html: SimpleCov::Formatter::HTMLFormatter,
    rcov: SimpleCov::Formatter::RcovFormatter
  }
  
  SimpleCov.formatter = SIMPLECOV_FORMATTERS.fetch(
                          ENV['COVERAGE'].to_sym,
                          SIMPLECOV_FORMATTERS[:html])
  puts "    * using formatter #{SimpleCov.formatter}".yellow
  SimpleCov.start do
    add_filter '/spec/'
    # TODO use add_group as soon as we have a meaningful grouping
  end
else
  puts ' * NOT Performing coverage via simplecov'.yellow
end

require 'gom_agents'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

setup_celluloid_logger(
  ENV['CELLULOID_LOGGER_OUT'] || 'stdout',
  ENV['CELLULOID_LOGGER_LEVEL'] || 'error'
)

Celluloid.shutdown_timeout = 1

RSpec.configure do |config|
  config.include AsyncHelpers
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  
  config.add_setting :fixture_path
  config.fixture_path = File.expand_path('fixtures', File.dirname(__FILE__))
  
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |c|
    c.syntax = :expect
  end
  
  config.order = 'random'
  
  config.around(:each) do |ex|
    ex.run
    reboot_celluloid
  end
  
end
