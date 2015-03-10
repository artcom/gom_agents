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

    def on_gnp(data)
      @callback.call(data)
    end

    def unsubscribe
      @observer.gnp_unsubscribe(self)
    end
  end

  class Observer
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    INACTIVITY_TIMEOUT = 60 # seconds

    def initialize(gom = nil)
      @gom = gom || Gom::Agents::App.gom
      ws_url = @gom.retrieve '/services/websockets_proxy:url'
      fail '"/services/websockets_proxy:url" not found in gom!' unless ws_url

      debug 'Gom::Observer - initializing'

      @ws_url = ws_url[:attribute][:value]
      @client = future.open_websocket @ws_url
      schedule_timeout

      @subscriptions = {}
    end

    def open_websocket(url)
      client = Celluloid::WebSocket::Client.new(url, Actor.current)
      link client
      client
    end

    def on_open
      debug "Gom::Observer -- websocket connection to #{@ws_url.inspect} opened"
    end

    def on_close(code, reason)
      debug "Gom::Observer -- websocket connection closed: #{code.inspect}, #{reason.inspect}"
    end

    def on_message(data)
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
      do_subscribe(path) if @subscriptions[path].empty?

      info "Gom::Observer -- adding subscription for #{path.inspect}"
      subscription = Subscription.new(Actor.current, path, &block)
      @subscriptions[path] << subscription

      subscription
    end

    def gnp_unsubscribe(subscription)
      path = subscription.path

      info "Gom::Observer -- removing subscription for #{path.inspect}"
      @subscriptions[path].delete(subscription)

      do_unsubscribe(path) if @subscriptions[path].empty?
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

    private

    def schedule_timeout
      timer = after(INACTIVITY_TIMEOUT) { fail 'GNP WebSocket Bridge not responding' }

      every(INACTIVITY_TIMEOUT / 2) do
        @client.value.ping { timer.reset }
      end
    end

    def do_subscribe(path)
      info "Gom::Observer -- subscribing to #{path.inspect}"
      send_command('subscribe', path)
    end

    def do_unsubscribe(path)
      info "Gom::Observer -- unsubscribing from #{path.inspect}"
      send_command('unsubscribe', path)
    end

    def send_command(command, path)
      @client.value.text({
        command: command,
        path: path
      }.to_json)
    end

    def handle_initial(data)
      payload = {
        uri: data['path'],
        initial: JSON.parse(data['initial'], symbolize_names: true)
      }

      @subscriptions[data['path']].each { |s| s.on_gnp payload }
    end

    def handle_gnp(data)
      payload = JSON.parse(data['payload'], symbolize_names: true)
      @subscriptions[data['path']].each { |s| s.on_gnp payload }
    end
  end
end
