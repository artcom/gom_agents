require 'celluloid/websocket/client'
require 'json'
require 'chromatic'

module EnttecGomDaemon

  class GomSubscription

    def initialize path, &callback
      @path = path
      @callback = callback
      @initial_retrieved = false

      def on_initial_data data
        return if @initial_retrieved
        @callback.call(data)
        @initial_retrieved = true
      end

      def on_change data
        @callback.call(data)
      end

    end
  end
  
  class GomObserver
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications
    
    def initialize gom = nil
      @gom = gom || App.gom
      ws_url = @gom.retrieve '/services/websockets_proxy:url'
      raise '"/services/websockets_proxy:url" not found in gom!' unless ws_url

      debug 'GomObserver - initializing'

      @client = future.open_websocket ws_url[:attribute][:value]

      @subscriptions = {}
    end

    def open_websocket url
      client = Celluloid::WebSocket::Client.new(url, current_actor)
      link client
      client
    end
   
    def on_open
      debug 'GomObserver -- websocket connection opened'
    end
    
    def on_close(code, reason)
      debug "GomObserver -- websocket connection closed: #{code.inspect}, #{reason.inspect}"
    end
    
    def on_message(data)
      # debug "GomObserver -- message received: #{data.inspect}"
      raw_data = JSON.parse(data)
      if raw_data.key? 'initial'
        handle_initial raw_data
      elsif raw_data.key? 'payload'
        handle_gnp raw_data
      else
        warn "unknown data package received: #{data.inspect} - IGNORING"
      end
    rescue JSON::ParserError => e
      error "receive a package that is not valid json: #{data.inspect} - IGNORING #{e}"
    end

    def gnp_subscribe path, &block
      info "GomObserver -- subscribing to #{path.inspect}"
      @client.value.text({
        command: 'subscribe',
        path: path
      }.to_json)
      @subscriptions[path] ||= []
      @subscriptions[path] << GomSubscription.new(path, &block)
    end
    
    def gnp_unsubscribe path
      info "GomObserver -- subscribing from #{path.inspect}"
      @client.future.text({
        command: 'unsubscribe',
        path: path
      }.to_json)
    end

    def handle_initial data
      payload = { uri: data['path'], initial: JSON.parse(data['initial'], symbolize_names: true) }
      @subscriptions[data['path']].each { |s| s.on_initial_data payload }  
    end

    def die!
      raise 'died intentionally'
    end

    def handle_gnp data
      payload = JSON.parse(data['payload'], symbolize_names: true)
      @subscriptions[data['path']].each { |s| s.on_change payload } 
    end

  end
  
end
