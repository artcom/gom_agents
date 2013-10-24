require 'spec_helper'

describe EnttecGomDaemon::DmxUniverse do

    let (:gom) { Gom::Client.new "http://gom:345" }
    let (:subscriber) { SimpleSubscriber.new 'dmx_universe' }
    before(:each) {
      @publisher = TestPublisher.new
      mock_observer = Celluloid::Actor[:gom_observer] = SimpleActor.new
      allow(mock_observer).to receive(:gnp_subscribe).with('/dmx/node/values')
    }
    subject { EnttecGomDaemon::DmxUniverse.new gom, '/dmx/node' }

    it "should have 512 entries in the values array" do
      allow(gom).to receive(:retrieve).with('/dmx/node/values.xml').and_return(<<-XML)
<?xml version="1.0"?>
<node ctime="2009-10-22T17:14:31+02:00" uri="/dmx/node/values" name="values" mtime="2009-10-22T17:14:31+02:00">
</node>
        XML
      expect(subject.dmx_values.size).to be(512)
    end
    
    it "should reject non integer DMX values" do
      allow(gom).to receive(:retrieve).with('/dmx/node/values.xml').and_return(<<-XML)
<?xml version="1.0"?>
<node ctime="2009-10-22T17:14:31+02:00" uri="/dmx/node/values" name="values" mtime="2009-10-22T17:14:31+02:00">
<attribute type="string" name="4" mtime="2009-10-22T17:14:31+02:00">abc</attribute>
</node>
        XML
      a = (Array.new 512, 0)
      expect(subject.dmx_values).to eq(a)
    end


    it "should reject out of range DMX values" do
      allow(gom).to receive(:retrieve).with('/dmx/node/values.xml').and_return(<<-XML)
<?xml version="1.0"?>
<node ctime="2009-10-22T17:14:31+02:00" uri="/dmx/node/values" name="values" mtime="2009-10-22T17:14:31+02:00">
<attribute type="string" name="2" mtime="2009-10-22T17:14:31+02:00">300</attribute>
<attribute type="string" name="3" mtime="2009-10-22T17:14:31+02:00">54321</attribute>
</node>
        XML
      a = (Array.new 512, 0)
      expect(subject.dmx_values).to eq(a)
    end

    it "should reject out or range DMX channels" do
      allow(gom).to receive(:retrieve).with('/dmx/node/values.xml').and_return(<<-XML)
<?xml version="1.0"?>
<node ctime="2009-10-22T17:14:31+02:00" uri="/dmx/node/values" name="values" mtime="2009-10-22T17:14:31+02:00">
<attribute type="string" name="600" mtime="2009-10-22T17:14:31+02:00">1</attribute>
<attribute type="string" name="0" mtime="2009-10-22T17:14:31+02:00">23</attribute>
<attribute type="string" name="1" mtime="2009-10-22T17:14:31+02:00">-10</attribute>
</node>
        XML
      a = (Array.new 512, 0)
      expect(subject.dmx_values).to eq(a)
    end

    it "should parse values from gom node" do
        subscriber
        subject
        @publisher.send_message 'gnp', {
          :uri =>"/dmx/node/values", 
          :initial => {
            :node=>{
              :entries=>[
                { :attribute=>{ :name=>"1", :value=>"1" } }, 
                { :attribute=>{ :name=>"17", :value=>"23" } }, 
                { :attribute=>{ :name=>"245", :value=>"177" } }
              ]
            }
          }
        } 
      a = (Array.new 512, 0)
      a[0] = 1; a[16] = 23; a[244] = 177
      expect(subject.dmx_values).to eq(a)
    end
    
      it 'emits correct dmx universe' do
      allow(gom).to receive(:retrieve).with('/dmx/node/values.xml').and_return(<<-XML)
<?xml version="1.0"?>
<node ctime="2009-10-22T17:14:31+02:00" uri="/dmx/node/values" name="values" mtime="2009-10-22T17:14:31+02:00">
</node>
        XML
        subscriber # trigger lazy 
        subject
        @publisher.send_message 'gnp', {
          :uri =>"/dmx/node/values", 
          :initial => {
            :node=>{
              :entries=>[]
            }
          }
        } 
        @publisher.send_message 'gnp', {
          :uri =>"/dmx/node/values:1", 
          :update => {
            :attribute=>{
              :name=>"1",
              :value=>"255"
            }
          }
        } 
        values = (Array.new 512, 0)
        values[0] = 255
        eventually {
          expect(subscriber.received_events.size).to eq(2)
          expect(subscriber.received_events.last).to eq(values)
        }
    end


end
