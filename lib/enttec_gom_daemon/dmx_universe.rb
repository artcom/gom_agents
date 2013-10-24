require 'gom/client'
require 'nokogiri'

module EnttecGomDaemon
  
  class DmxUniverse
    
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications
   
    attr_reader :dmx_values

    # TODO do not hardwire port
    def initialize gom, gom_path
      @gom = gom
      @gom_path = gom_path
      @dmx_values = (Array.new 512, 0)

      Actor[:gom_observer].async.gnp_subscribe "#{@gom_path}/values"


      #xml = @gom.retrieve "#{@gom_path}/values.xml"
      #(Nokogiri::parse xml).xpath("//attribute").each do |a|
      #  begin
      #    chan = Integer(a.attributes['name'].to_s)
      #    val = Integer(a.text)
      #    validate_dmx_range chan, val
      #    @dmx_values[chan-1] = val
      #  rescue => e
      #    info " ## #{e}"
      #  end
      #end
      subscribe 'gnp', :on_gnp
    end
   
    def on_gnp _, gnp
      debug "GNP:#{gnp.inspect}"
      case gnp[:uri]
      when %r|#{@gom_path}/values:(.*)$|
        on_channel_gnp gnp 
      when %r|#{@gom_path}/values$|
        on_universe_gnp gnp
      end
    end

    def on_universe_gnp gnp
      debug "UNIVERSE #{gnp.inspect}"
      updates = []
      if gnp.key?(:initial)
        gnp[:initial][:node][:entries].each do |entry|
          if entry.key?(:attribute)
            updates << [Integer(entry[:attribute][:name]), 
                        Integer(entry[:attribute][:value])]
          end
        end
        update_values updates
      end
    end

    def on_channel_gnp gnp
      debug "CHANNEL #{gnp.inspect}"
      updates = []
      debugger
      if gnp.key?(:update) && gnp[:update].key?(:attribute)
        attribute = gnp[:update][:attribute]
        updates << [Integer(attribute[:name]), 
                    Integer(attribute[:value])]
        update_values updates
      end
    end

    def update_values updates
      updates.each do |channel, value|
        validate_dmx_range channel, value
        @dmx_values[channel-1] = value
      end
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
