module Enttec

  # needs:
  #   GOM DMX Service Node URL which includes a device_file attribute and a
  #   values subnode: 
  #
  #   +-- /services/enttec-dmx-usb-pro
  #        |
  #        |-- :device_file
  #        |
  #        +-- values
  #              |-- :1
  #              |-- :5
  #             ...
  #              +-- :27
  # 
  class GomSession

    Defaults = { }

    attr_reader :initial_uri, :connection

    # dmx_node_url: http://<gom server>/<dmx node path>
    #
    def initialize dmx_node_url, options = {}
      @options = (Defaults.merge options)

      server_url, @initial_uri = (GomSession::split_url dmx_node_url)
      @connection = Gom::Remote::Connection.new server_url

      @values = (Array.new 256, 0)
    end

    def values
      require 'nokogiri'
      xml = (@connection.read "#{@initial_uri}/values.xml")
      (Nokogiri::parse xml).xpath("//attribute").each do |a|
        chan = Integer(a.attributes['name'].to_s)
        @values[chan] = Integer(a.text)
      end

      @values
    end

    def device_file
      @device_file ||= (@connection.read "#{@initial_uri}:device_file.txt")
    end

    def on_values &callback
      raise "not yet implemented"
      @on_values_cb = callback
    end
  end
end