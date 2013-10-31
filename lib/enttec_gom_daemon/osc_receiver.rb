require 'osc-ruby'

module EnttecGomDaemon
  
  class OscReceiver
    include Celluloid::IO
    include Celluloid::Logger
    include Celluloid::Notifications
    
    MAX_SIZE = 16_384
    
    def initialize 
      @port = begin
        App.gom.retrieve("#{App.app_node}:osc_port")[:attribute][:value]
      rescue
        Celluloid::Logger.error "#{App.app_node}:osc_port missing - not starting OSC server" if @osc_port.nil?
        nil
      end
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
        dgram, network = @socket.recvfrom(MAX_SIZE)
        # info "UDP -- incoming raw message: '#{dgram}'"
        begin
          ip_info = Array.new
          ip_info << network[1]
          ip_info.concat(network[2].split('.'))
          on_udp_dgram dgram, ip_info
        rescue EOFError
          warn 'truncated UDP packet - discarding'
        end
      end
    end

    def on_udp_dgram dgram, ip_info = nil
      updates = []
      OSC::OSCPacket.messages_from_network(dgram, ip_info).each do |message|
        address = message.address
        address.slice!(0) if address.start_with?('/')
        namespace, universe, channel = address.split('/', 3)
        if namespace == 'light' && universe == '1'
          updates << { channel: Integer(channel), value: Integer(message.to_a.first), cache_dirty: true }
        else
          warn "Unsupported namespace or universe: '#{message.address}'"
        end
      end
      info "#{self.class} received channel updates: #{updates}"
      publish 'dmx_updates', updates
    end

    def die!
      raise 'died intentionally'
    end

  end
  
end
