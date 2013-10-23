require 'optparse'
require 'singleton'

# starts the notification pubsub subsystem
require 'celluloid/autostart'

module EnttecGomDaemon
  
  class App
    
    include Singleton
    
    def parse(argv = ARGV)
      @parser = OptionParser.new do |o|
        o.on '-v', '--version', 'version of this application' do |arg|
          puts VERSION
          exit(0)
        end
      end
      @parser.banner = "#{$0} [gom-node-uri]"
      @parser.parse!(argv)
      @@gom_uri = URI.parse(argv.first)
    end
   
    def path
      @@gom_uri.path
    end

    def run
      #SensorInput.supervise_as :sensor_input, UDP_SENSOR_PORT, UDP_PACKAGE_RECEIVE_SIZE
      #UdpPipesManager.supervise_as :udp_pipes_manager
      #Recorder.supervise_as :recorder, RECORDING_DIR
      #Player.supervise_as :player, RECORDING_DIR
      WebServer.supervise_as :reel, WEB_SERVER_PORT
      sleep
    end
    
  end
  
end
