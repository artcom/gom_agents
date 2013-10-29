require 'gom/client'

module EnttecGomDaemon
  
  class DmxUniverse
    
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications
   
    attr_reader :dmx_values

    # TODO do not hardwire port
    def initialize values_path = nil
      @values_path = values_path || "#{App.app_node}/values"
      @dmx_values = (Array.new 512, 0)
      @rdmx = Rdmx::Dmx.new App.device_file unless App.device_file.nil? 

      debug 'DmxUniverse -- initializing'
      subscribe 'dmx_updates', :update_values
      link Celluloid::Actor[:gom_observer]
      Actor[:gom_observer].async.gnp_subscribe @values_path

    end
   
    def update_values _, updates
      updates.each do |update|
        begin
          c = Integer(update[:channel])
          v = Integer(update[:value])
          validate_dmx_range c, v
          @dmx_values[c-1] = v
        rescue => e
          warn " ## #{e}"
        end
      end
      @rdmx.write *(@dmx_values) unless @rdmx.nil?
      publish 'dmx_universe', @dmx_values
    end

  private
    def validate_dmx_range chan, value
      if(chan < 1 or 512 < chan)
        raise RangeError, "DMX channel out of range: #{chan}"
      end
      if(value < 0 or 256 <= value) 
        raise RangeError, "DMX value out of range: #{value}"
      end
    end

  end

end
