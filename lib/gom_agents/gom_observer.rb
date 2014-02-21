require 'celluloid/websocket/client'
require 'json'
require 'chromatic'

module Gom
  class Subscription
    attr_reader :path

    def initialize(path, &callback)
      @path = path
      @callback = callback
      @initial_retrieved = false
    end

    def on_initial_data(data)
      return if @initial_retrieved
      @callback.call(data)
      @initial_retrieved = true
    end

    def on_change(data)
      @callback.call(data)
    end
  end

  class Observer
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    def initialize(gom = nil)
      @gom = gom || Gom::Agents::App.gom
      ws_url = @gom.retrieve '/services/websockets_proxy:url'
      fail '"/services/websockets_proxy:url" not found in gom!' unless ws_url

      debug 'Gom::Observer - initializing'

      @ws_url = ws_url[:attribute][:value]
      @client = future.open_websocket @ws_url

      @subscriptions = {}
    end

    def open_websocket(url)
      client = Celluloid::WebSocket::Client.new(url, current_actor)
      link client
      client
    end

    def on_open
      debug %Q|Gom::Observer -- websocket connection to #{@ws_url.inspect} opened|
    end

    def on_close(code, reason)
      debug "Gom::Observer -- websocket connection closed: #{code.inspect}, #{reason.inspect}"
    end

    def on_message(data)
      # debug "Gom::Observer -- message received: #{data.inspect}"
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

    def gnp_subscribe(path, &block)
      @subscriptions[path] ||= []

      if @subscriptions[path].empty?
        info "Gom::Observer -- subscribing to #{path.inspect}"
        @client.value.text({
          command: 'subscribe',
          path: path
        }.to_json)
      end

      info "Gom::Observer -- adding subscription for #{path.inspect}"
      subscription = Subscription.new(path, &block)
      @subscriptions[path] << subscription

      subscription
    end

    def gnp_unsubscribe(subscription)
      path = subscription.path

      info "Gom::Observer -- removing subscription for #{path.inspect}"
      @subscriptions[path].delete(subscription)

      if @subscriptions[path].empty?
        info "Gom::Observer -- unsubscribing from #{path.inspect}"
        @client.value.text({
          command: 'unsubscribe',
          path: path
        }.to_json)
      end
    end

    def handle_initial(data)
      payload = { uri: data['path'], initial: JSON.parse(data['initial'], symbolize_names: true) }
      @subscriptions[data['path']].each { |s| s.on_initial_data payload }
    end

    def die!
      fail 'died intentionally'
    end

    def handle_gnp(data)
      payload = JSON.parse(data['payload'], symbolize_names: true)
      @subscriptions[data['path']].each { |s| s.on_change payload }
    end
  end
end
