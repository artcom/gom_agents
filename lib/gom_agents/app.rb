require 'optparse'
require 'singleton'

module Gom
  module Agents
    class App
      include Singleton

      class Supervisor < Celluloid::SupervisionGroup; end

      def run
        # starts the notification pubsub subsystem
        require 'celluloid/autostart'

        Supervisor.supervise Gom::Observer, as: :gom_observer if App.gom

        # more_actors
        Gom::Agents.autostart if Gom::Agents.methods.include?(:autostart)

        Supervisor.run
      end

      class << self
        attr_reader :gom, :app_node

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
          if argv.empty?
            warn 'GOM uri missing! not starting gom support!'
          else
            gom_uri = URI.parse(argv.first) + '/'
            @app_node = URI.parse(argv.first).path.chomp('/')
            @gom =  Gom::Client.new gom_uri.to_s
          end
        end
      end
    end
  end
end
