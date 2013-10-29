require 'gom/client'

module EnttecGomDaemon
  
  class DmxUniverse
    
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications
  
    INACTIVITY_TIMEOUT = 5 # seconds to wait for inactivity

    attr_reader :dmx_values

    def initialize values_path = nil
      @values_path = values_path || "#{App.app_node}/values"
      @dmx_values = (Array.new 512, nil) # nil means not-in-gom (eq '0')
      @rdmx = Rdmx::Dmx.new App.device_file unless App.device_file.nil? 

      debug 'DmxUniverse -- initializing'
      link Celluloid::Actor[:gom_observer]
      subscribe 'dmx_updates', :update_values
      Actor[:gom_observer].async.gnp_subscribe @values_path
    end
   
    def update_values _, updates
      updates.each do |update|
        begin
          c = Integer(update[:channel])
          v = update[:value].nil? ? nil : Integer(update[:value])
          validate_dmx_range c, v
          @dmx_values[c-1] = v
        rescue => e
          warn " ## #{e}"
        end
      end
      # change nil values to '0'
      @rdmx.write *(@dmx_values.collect {|x| x || 0 }) unless @rdmx.nil?
      publish 'dmx_universe', @dmx_values
      if @timer
        @timer.reset
      else
        @timer = after(INACTIVITY_TIMEOUT) { persist }
      end
    end

  private
    def validate_dmx_range chan, value
      if(chan < 1 or 512 < chan)
        raise RangeError, "DMX channel out of range: #{chan}"
      end
      if(not value.nil? and (value < 0 or 256 <= value)) 
        raise RangeError, "DMX value out of range: #{value}"
      end
    end

    def persist
      info "#{current_actor.class} - persisting to gom"
      attributes = {}
      @dmx_values.each_with_index { |value, index|
        attributes[(index+1).to_s] = value if value
      }
      @timer = nil
      App.gom.update! @values_path, attributes
    end

  end

end
