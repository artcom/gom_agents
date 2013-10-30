require 'optparse'
require 'singleton'

# starts the notification pubsub subsystem
require 'celluloid/autostart'

module EnttecGomDaemon
  
  class App

    include Singleton
    
    def run
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
        end
        parser.banner = "#{$PROGRAM_NAME} [gom-node-uri]"
        parser.parse!(argv)
        gom_uri = URI.parse(argv.first) + '/'
        @app_node = URI.parse(argv.first).path
        @gom =  Gom::Client.new gom_uri.to_s
        @device_file = begin
          gom.retrieve("#{@app_node}:device_file")[:attribute][:value]
        rescue
          Celluloid::Logger.error "#{@app_node}:device_file missing - not opening serial port"
          nil
        end
        @osc_port = begin
          gom.retrieve("#{@app_node}:osc_port")[:attribute][:value]
        rescue
          Celluloid::Logger.error "#{@app_node}:osc_port missing - not starting OSC server" if @osc_port.nil?
          nil
        end
      end
    end

    class S < Celluloid::SupervisionGroup
      supervise(GomObserver, as: :gom_observer, block: lambda { |current_actor, data|
        updates = GnpDmxAdapter.on_gnp data 
        current_actor.publish 'dmx_updates', updates unless updates.empty?
      })
      supervise DmxUniverse, as: :dmx_universe
      supervise OscReceiver, as: :osc_receiver
    end
    
  end
  
end
