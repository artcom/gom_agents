require 'celluloid/websocket/client'
require 'json'
require 'chromatic'

module Gom
  class Subscription
    attr_reader :path

    def initialize(observer, path, &callback)
      @observer = observer
      @path = path
      @callback = callback
    end

    def notify(payload)
      @callback.call(payload)
    end

    def unsubscribe
      @observer.gnp_unsubscribe(self)
    end
  end

  class Connection
    include Celluloid
    include Celluloid::Logger

    PING_INTERVAL = 30 # seconds
    INACTIVITY_TIMEOUT = 2 * PING_INTERVAL + 5 # seconds

    def initialize(url, handler)
      @client = future.open_websocket(url, handler)
      schedule_timeout
    end

    def send(data)
      @client.value.text(data)
    end

    def open_websocket(url, handler)
      client = Celluloid::WebSocket::Client.new(url, handler)
      link client
      client
    end

    private

    def schedule_timeout
      timer = after(INACTIVITY_TIMEOUT) { fail 'GNP WebSocket Bridge not responding' }

      every(PING_INTERVAL) do
        @client.value.ping { timer.reset }
      end
    end
  end

  class Observer
    include Celluloid
    include Celluloid::Logger

    RECONNECT_DELAY = 30 # seconds

    trap_exit :actor_died

    def initialize(gom = nil)
      @gom = gom || Gom::Agents::App.gom
      ws_url = @gom.retrieve '/services/websockets_proxy:url'
      fail '"/services/websockets_proxy:url" not found in gom!' unless ws_url

      debug 'Gom::Observer - initializing'

      @ws_url = ws_url[:attribute][:value]
      @subscriptions = {}

      connect
    end

    def connect
      @connected = false
      @connection = Connection.new_link(@ws_url, Actor.current)
    end

    def reconnect
      after(RECONNECT_DELAY) { connect }
    end

    def actor_died(actor, reason)
      reconnect if actor == @connection
    end

    def gnp_subscribe(path, &block)
      @subscriptions[path] ||= []
      do_subscribe(path) if @connected && @subscriptions[path].empty?

      info "Gom::Observer -- adding subscription for #{path.inspect}"
      subscription = Subscription.new(Actor.current, path, &block)
      @subscriptions[path] << subscription

      subscription
    end

    def gnp_unsubscribe(subscription)
      path = subscription.path

      info "Gom::Observer -- removing subscription for #{path.inspect}"
      @subscriptions[path].delete(subscription)

      do_unsubscribe(path) if @connected && @subscriptions[path].empty?
    end

    EVENTS = %i(initial create update delete)

    def on_attribute(path)
      gnp_subscribe(path) do |data|
        EVENTS.each do |event|
          if data.key?(event)
            value = data[event][:attribute][:value]
            path = data[:uri]
            yield value, event, path
          end
        end
      end
    end

    def on_open
      debug "Gom::Observer -- websocket connection to #{@ws_url.inspect} opened"
      @connected = true
      @subscriptions.keys.each { |path| do_subscribe(path) }
    end

    def on_close(code, reason)
      debug "Gom::Observer -- websocket connection closed: #{code.inspect}, #{reason.inspect}"
      @connected = false
      reconnect
    end

    def on_message(data)
      json = JSON.parse(data, symbolize_names: true)
      path = json[:path]
      payload = extract_payload(json)

      if path && payload
        handle_gnp(path, payload)
      else
        warn "unknown data package received: #{data.inspect} - IGNORING"
      end
    rescue JSON::ParserError => e
      error "receive a package that is not valid json: #{data.inspect} - IGNORING #{e}"
    end

    private

    def do_subscribe(path)
      info "Gom::Observer -- subscribing to #{path.inspect}"
      send_command('subscribe', path)
    end

    def do_unsubscribe(path)
      info "Gom::Observer -- unsubscribing from #{path.inspect}"
      send_command('unsubscribe', path)
    end

    def send_command(command, path)
      @connection.send({
        command: command,
        path: path
      }.to_json)
    end

    def extract_payload(json)
      if json.key?(:initial)
        { uri: json[:path], initial: JSON.parse(json[:initial], symbolize_names: true) }
      elsif json.key?(:payload)
        JSON.parse(json[:payload], symbolize_names: true)
      else
        nil
      end
    end

    def handle_gnp(path, payload)
      @subscriptions[path].each { |s| s.notify payload }
    end
  end
end
