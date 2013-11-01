require 'gom/client'

module EnttecGomDaemon
  
  class DmxUniverse
    
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications
  
    INACTIVITY_TIMEOUT = 5 # seconds to wait for inactivity

    attr_reader :dmx_values, :device_file

    def initialize values_path = nil
      @values_path = values_path || "#{App.app_node}/values"
      @dmx_values = (Array.new 512, nil) # nil means not-in-gom (eq '0')
      @device_file = begin
        App.gom.retrieve("#{App.app_node}:device_file")[:attribute][:value]
      rescue
        Celluloid::Logger.error "#{App.app_node}:device_file missing - not opening serial port"
        nil
      end
      @rdmx = Rdmx::Dmx.new @device_file unless @device_file.nil? 

      debug 'DmxUniverse -- initializing'
      link Celluloid::Actor[:gom_observer]
      subscribe 'dmx_updates', :update_values
      Actor[:gom_observer].gnp_subscribe @values_path do |data|
        updates = GnpDmxAdapter.on_gnp data
        update_values nil, updates unless updates.empty?
      end
      Actor[:gom_observer].gnp_subscribe @values_path do |data|
        info "LEFT  HAND received #{data}"
      end
      Actor[:gom_observer].gnp_subscribe @values_path do |data|
        info "RIGHT HAND received #{data}"
      end
    end
   
    def update_values _, updates
      cache_dirty = false
      updates.each do |update|
        begin
          c = Integer(update[:channel])
          v = update[:value].nil? ? nil : Integer(update[:value])
          validate_dmx_range c, v
          @dmx_values[c - 1] = v
          cache_dirty ||= update[:cache_dirty]
        rescue => e
          warn " ## #{e}"
        end
      end
      # change nil values to '0'
      @rdmx.write(*(@dmx_values.collect { |x| x || 0 })) unless @rdmx.nil?
      publish 'dmx_universe', @dmx_values
      if cache_dirty
        if @timer
          @timer.reset
        else
          @timer = after(INACTIVITY_TIMEOUT) { persist }
        end
      end
    end

    private

    def validate_dmx_range chan, value
      if chan < 1 || 512 < chan
        raise RangeError, "DMX channel out of range: #{chan}"
      end
      if (!value.nil?) && (value < 0 || 256 <= value) 
        raise RangeError, "DMX value out of range: #{value}"
      end
    end

    def persist
      info "#{current_actor.class} - persisting to gom"
      attributes = {}
      @dmx_values.each_with_index { |value, index|
        attributes[(index + 1).to_s] = value if value
      }
      @timer = nil
      App.gom.update! @values_path, attributes
    end

  end

end
