require 'celluloid/websocket/client'
require 'json'
require 'chromatic'

module EnttecGomDaemon
  
  class GomObserver
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications
    
    def initialize gom = nil
      @gom = gom || App.gom
      @channel = "gnp"
      ws_url = @gom.retrieve "/services/websockets_proxy:url"
      raise "'/services/websockets_proxy:url' not found in gom!" unless ws_url

      debug "GomObserver - initializing"

      @client = future.open_websocket ws_url[:attribute][:value]

      # subscribe channel, :debug_sub
    end

    def open_websocket url
      client = Celluloid::WebSocket::Client.new(url, current_actor)
      link client
      client
    end
   
    #def debug_sub c,p
    #  debug "#{c.inspect} / #{p.inspect}"
    #end

    def on_open
      debug 'GomObserver -- websocket connection opened'
    end
    
    def on_close(code, reason)
      debug "GomObserver -- websocket connection closed: #{code.inspect}, #{reason.inspect}"
    end
    
    def on_message(data)
      debug "GomObserver -- message received: #{data.inspect}"
      raw_data = JSON.parse(data)
      if raw_data.key? 'initial'
        handle_initial raw_data
      elsif raw_data.key? 'payload'
        handle_gnp raw_data
      else
        warn "unknown data package received: #{data.inspect} - IGNORING"
      end
    rescue JSON::ParserError => e
      error "receive a package that is not valid json: #{data.inspect} - IGNORING"
    end

    def gnp_subscribe path
      info "GomObserver -- subscribing to #{path.inspect}"
      @client.value.text({
        command: 'subscribe',
        path: path
      }.to_json)
    end
    
    def gnp_unsubscribe path
      info "GomObserver -- subscribing from #{path.inspect}"
      @client.future.text({
        command: 'unsubscribe',
        path: path
      }.to_json)
    end

    def handle_initial data
      payload = { :uri => data['path'], :initial => JSON.parse(data['initial'], :symbolize_names => true) } 
      publish @channel, payload 
      # puts "handle_initial: #{payload.inspect}".yellow
    end

    def die!
      raise "died intentionally"
    end

    def handle_gnp data
      payload = JSON.parse(data['payload'], :symbolize_names => true)
      publish @channel, payload 
      puts "handle_gnp: #{payload.inspect}".yellow
    end

  end
  
end
