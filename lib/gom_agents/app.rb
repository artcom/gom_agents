require 'optparse'
require 'singleton'

# starts the notification pubsub subsystem
require 'celluloid/autostart'

module Gom
  module Agents 
  
    class App

      include Singleton

      class S < Celluloid::SupervisionGroup; end

      def run
        S.supervise Gom::Observer, as: :gom_observer

        # more_actors
        Gom::Agents.autoload

        S.run
      end

      class << self
        attr_reader :gom, :app_node, :device_file, :osc_port

        def parse(argv = ARGV)
          parser = OptionParser.new do |o|
            o.on '-v', '--version', 'version of this application' do |arg|
              puts VERSION
              exit(0)
            end
            o.on '-l', '--logfile [logfile]', String, 'log to this instead of stdout' do |arg|
              Celluloid.logger = ::Logger.new(arg)
            end
          end
          parser.banner = "#{$PROGRAM_NAME} [gom-node-uri]"
          parser.parse!(argv)
          gom_uri = URI.parse(argv.first) + '/'
          @app_node = URI.parse(argv.first).path
          @gom =  Gom::Client.new gom_uri.to_s
        end
      end

    end
  end  
end
