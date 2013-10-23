require File.dirname(__FILE__)+'/../spec_helper'

describe EnttecGomDaemon::WebServer do

  describe "with a dmx node it" do
    before :each do
      @gom, path = (Gom::Remote::Connection.init 'http://gom:345/dmx/node')
      @gom.should_not == nil
      @dmx = (Enttec::DmxNode.new path)
    end

    it "should load the device_file name" do
      @gom.should_receive(:read).
        with("/dmx/node:device_file.txt").
        and_return('/dev/cu.usbserial-ENRV27QZ')
      @dmx.device_file.should == '/dev/cu.usbserial-ENRV27QZ'
    end

    it "should parse values from gom node" do
      @gom.should_receive(:read).with('/dmx/node/values.xml').and_return(<<-XML)
<?xml version="1.0"?>
<node ctime="2009-10-22T17:14:31+02:00" uri="/dmx/node/values" name="values" mtime="2009-10-22T17:14:31+02:00">
<attribute type="string" name="1" mtime="2009-10-22T17:14:31+02:00">1</attribute>
<attribute type="string" name="17" mtime="2009-10-22T17:14:31+02:00">23</attribute>
<attribute type="string" name="245" mtime="2009-10-22T17:14:31+02:00">177</attribute>
</node>
        XML
      a = (Array.new 512, 0)
      a[0] = 1; a[16] = 23; a[244] = 177
      @dmx.values.should == a
    end
  end
end
