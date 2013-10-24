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

  end
end
