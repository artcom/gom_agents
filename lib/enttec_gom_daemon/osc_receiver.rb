require 'osc-ruby'

module EnttecGomDaemon
  
  class OscReceiver
    include Celluloid::IO
    include Celluloid::Logger
    include Celluloid::Notifications
    
    MaxSize = 16384
    
    def initialize options = {}
      @port = options.key?(:port) ? options[:port] : App.osc_port
      if @port
        @socket = UDPSocket.new
        @socket.bind '0.0.0.0', @port
        async.listen
        debug "#{self.class} - listening on port #{@port}"
      end
    end
    
    def finalize
      @socket.close if @socket
    end
    
    def listen
      loop do
        dgram, network = @socket.recvfrom( MaxSize )
        info "UDP -- incoming raw message: '#{dgram}'"
        begin
          ip_info = Array.new
          ip_info << network[1]
          ip_info.concat(network[2].split('.'))
          on_udp_dgram dgram, ip_info
        rescue EOFError
        end
      end
    end

    def on_udp_dgram dgram, ip_info=nil
      updates = []
      OSC::OSCPacket.messages_from_network( dgram, ip_info ).each do |message|
        address = message.address
        address.slice!(0) if address.start_with?("/")
        namespace, universe, channel = address.split("/",3)
        if namespace == "light" and universe == "1"
          updates << { :channel => Integer(channel), :value => Integer(message.to_a.first) }
        else
          warn "Unsupported namespace or universe: '#{message.address}'"
        end
      end
      publish "dmx_updates", updates
    end

    def die!
      raise "died intentionally"
    end

  end
  
end
