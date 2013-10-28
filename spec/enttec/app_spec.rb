require 'spec_helper'

describe EnttecGomDaemon do

  specify { expect(subject).to respond_to(:version) }
  specify { expect(subject).to have_constant(:VERSION) }
  specify { expect(subject::VERSION).to eq(subject.version) }
  
end

describe EnttecGomDaemon::App do
  subject { EnttecGomDaemon::App }
  
  before(:each) do
    allow_message_expectations_on_nil
    allow(Gom::Client).to receive(:new).with('http://gom:345/')
    allow(subject.gom).to receive(:retrieve).
      with("/dmx/node:device_file").
      and_return(
        {:attribute=>
          { :name=>"device_file", 
            :node=>"/dnx/node", 
            :value=>"/dev/cu.usbserial-ENRV27QZ", 
            :type=>"string", 
            :mtime=>"2013-10-28T12:25:34+01:00", 
            :ctime=>"2013-10-28T12:25:34+01:00"
          }
        })
    subject.parse ['http://gom:345/dmx/node']
  end

  it "should initialize with GOM node path" do
      expect(subject.app_node).to eq('/dmx/node') 
  end

  it "should load the device_file name" do
    expect(subject.device_file).to eq('/dev/cu.usbserial-ENRV27QZ')
  end
end
