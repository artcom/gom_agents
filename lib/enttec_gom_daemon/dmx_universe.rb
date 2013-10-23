require 'gom/client'
require 'nokogiri'

module EnttecGomDaemon
  
  class DmxUniverse
    
    include Celluloid::Notifications
    include Celluloid::Logger
   
    attr_reader :dmx_values

    # TODO do not hardwire port
    def initialize gom, gom_path
      @gom = gom
      @gom_path = gom_path
      @dmx_values = (Array.new 512, 0)

      xml = @gom.retrieve "#{@gom_path}/values.xml"
      (Nokogiri::parse xml).xpath("//attribute").each do |a|
        begin
          chan = Integer(a.attributes['name'].to_s)
          val = Integer(a.text)
          validate_dmx_range chan, val
          @dmx_values[chan-1] = val
        rescue => e
          info " ## #{e}"
        end
      end
    end
    
    def update_channel channel, value 
      validate_dmx_range channel, value
      @dmx_values[channel-1] = value
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
