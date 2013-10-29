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
        parser.banner = "#{$0} [gom-node-uri]"
        parser.parse!(argv)
        gom_uri = URI.parse(argv.first)+"/"
        @app_node = URI.parse(argv.first).path
        @gom =  Gom::Client.new gom_uri.to_s
        @device_file = gom.retrieve("#{@app_node}:device_file")[:attribute][:value]
        @osc_port = gom.retrieve("#{@app_node}:osc_port")[:attribute][:value]
      end
    end

    class S < Celluloid::SupervisionGroup
      supervise(GomObserver, as: :gom_observer, block: lambda { |current_actor, data|
        updates = GnpDmxAdapter.on_gnp data 
        current_actor.publish "dmx_updates", updates
      })
      supervise DmxUniverse, as: :dmx_universe
      supervise OscReceiver, as: :osc_receiver
    end
    
  end
  
end
