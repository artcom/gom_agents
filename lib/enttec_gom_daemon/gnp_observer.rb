require 'reel'
require 'json'

module EnttecGomDaemon
  
  class GnpObserver < Reel::Server
    
    include Celluloid::Notifications
    include Celluloid::Logger
    
    # TODO do not hardwire port
    def initialize(host = '0.0.0.0', port = 1234)
      info "EnttecGomDaemon::GnpObserver starting on #{host}:#{port}"
      @dmx_values = (Array.new 512, 0)
      super(host, port, &method(:on_connection))
    end
    
    def on_connection(connection)
      connection.each_request do |request|
        if request.websocket?
          info 'HTTP -- Received a WebSocket connection'
          request << "websockets not supported."
          request.close
        else
          route_request connection, request
        end
      end
    end
    
    def route_request(connection, request)
      # nothing for now - could be incoming gnps
      # puts request.inspect, connection.inspect
      info "HTTP -- incoming request: #{request.method} - #{request.path} : #{request.body}"
      
      if request.method == 'POST'
        case request.path
        when '/gnp'
          handle_gnp command, request
        else
          default_response connection, request
        end
      elsif request.method == 'GET'
        case request.path
        when '/status'
          render_status connection, request
        else
          default_response connection, request
        end
      else
        default_response connection, request
      end
    end
    
    def default_response(connection, request)
      connection.respond :ok, 'OK'
    end
    
    def handle_gnp connection, request
      info 'HTTP - GNP detected'
      default_response connection, request
    end
    
    def render_status connection, request
      info 'GnpObserver -- render_status'
      Celluloid::Actor.all.each { |actor| 
        puts actor
      }
      connection.respond :ok, 'OK'
    end
  
    def process_gnp operation, attribute
      chan, val = (Integer attribute["name"]), (Integer attribute["value"])
      # validate_dmx_range chan, val
      @dmx_values[chan-1] = val
      publish 'dmx_values', @dmx_values
    end
  end


end
