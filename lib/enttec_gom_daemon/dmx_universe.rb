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
      subscribe 'gnp', :on_gnp
      # puts Celluloid::Actor[:gom_observer] 
      link Celluloid::Actor[:gom_observer]
      Actor[:gom_observer].async.gnp_subscribe @values_path

    end
   
    def on_gnp _, gnp
      case gnp[:uri]
      when %r|#{@values_path}:(.*)$|
        on_channel_gnp gnp 
      when %r|#{@values_path}$|
        on_universe_gnp gnp
      end
    end

    def on_universe_gnp gnp
      # debug "UNIVERSE #{gnp.inspect}"
      updates = []
      if gnp.key?(:initial)
        gnp[:initial][:node][:entries].each do |entry|
          if entry.key?(:attribute)
            updates << [entry[:attribute][:name], entry[:attribute][:value]]
          end
        end
        update_values updates
      end
    end

    def on_channel_gnp gnp
      # debug "CHANNEL #{gnp.inspect}"
      updates = []
      if gnp.key?(:update) && gnp[:update].key?(:attribute) 
        attribute = gnp[:update][:attribute]
        updates << [attribute[:name], attribute[:value]]
        update_values updates
      elsif gnp.key?(:create) && gnp[:create].key?(:attribute) 
        attribute = gnp[:create][:attribute]
        updates << [attribute[:name], attribute[:value]]
        update_values updates
      elsif gnp.key?(:delete) && gnp[:delete].key?(:attribute) 
        attribute = gnp[:delete][:attribute]
        updates << [attribute[:name], 0]
        update_values updates
      else
        warn "unsupported gnp '#{gnp.inspect}'"
      end
    end

    def update_values updates
      updates.each do |channel, value|
        begin
          c = Integer(channel)
          v = Integer(value)
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
