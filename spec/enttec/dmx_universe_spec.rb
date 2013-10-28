require 'spec_helper'

describe EnttecGomDaemon::DmxUniverse do

  let (:subscriber) { SimpleSubscriber.new 'dmx_universe' }
  before(:each) {
    @publisher = TestPublisher.new
    @mock_observer = Celluloid::Actor[:gom_observer] = SimpleActor.new
    allow(@mock_observer.async).to receive(:gnp_subscribe).with('/dmx/node/values')
    allow(EnttecGomDaemon::App).to receive(:device_file).and_return(nil)
  }
  subject { EnttecGomDaemon::DmxUniverse.new '/dmx/node/values' }

  it "should subscribe to the values node" do
    expect(@mock_observer.async).to receive(:gnp_subscribe).with('/dmx/node/values')
    subject
  end

  it "should have 512 entries in the values array" do
    subject
    @publisher.send_message 'gnp', {
      :uri =>"/dmx/node/values", 
      :initial => {
        :node=>{
          :entries=>[
          ]
        }
      }
    } 
    expect(subject.dmx_values.size).to be(512)
  end
  
  it "should reject non integer DMX values" do
    subject
    @publisher.send_message 'gnp', {
      :uri =>"/dmx/node/values", 
      :initial => {
        :node=>{
          :entries=>[
            { :attribute=>{ :name=>"1", :value=>"1" } }, 
            { :attribute=>{ :name=>"4", :value=>"s2" } }, 
          ]
        }
      }
    } 
    a = (Array.new 512, 0)
    a[0] = 1
    expect(subject.dmx_values).to eq(a)
  end


  it "should reject out of range DMX values" do
    subject
    @publisher.send_message 'gnp', {
      :uri =>"/dmx/node/values", 
      :initial => {
        :node=>{
          :entries=>[
            { :attribute=>{ :name=>"512", :value=>"1" } }, 
            { :attribute=>{ :name=>"2", :value=>"300" } }, 
            { :attribute=>{ :name=>"3", :value=>"54321" } }, 
            { :attribute=>{ :name=>"4", :value=>"-1" } }, 
          ]
        }
      }
    } 
    a = (Array.new 512, 0)
    a[511] = 1
    expect(subject.dmx_values).to eq(a)
  end

  it "should reject out or range DMX channels" do
    subject
    @publisher.send_message 'gnp', {
      :uri =>"/dmx/node/values", 
      :initial => {
        :node=>{
          :entries=>[
            { :attribute=>{ :name=>"1", :value=>"1" } }, 
            { :attribute=>{ :name=>"600", :value=>"1" } }, 
            { :attribute=>{ :name=>"0", :value=>"1" } }, 
          ]
        }
      }
    } 
    a = (Array.new 512, 0)
    a[0] = 1
    expect(subject.dmx_values).to eq(a)
  end

  it "should parse values from gom node" do
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

  context 'when receiving a GNP' do

    before(:each) {
      subscriber # trigger lazy 
      subject # trigger lazy
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
      @expected = (Array.new 512, 0)
      @expected[0] = 1; @expected[16] = 23; @expected[244] = 177
    }

    it 'processes GOM updates' do
      @publisher.send_message 'gnp', {
        :uri =>"/dmx/node/values:1", 
        :update => {
          :attribute=>{
            :name=>"1",
            :value=>"255"
          }
        }
      } 
      @expected[0] = 255
      eventually {
        expect(subscriber.received_events.size).to eq(2)
        expect(subscriber.received_events.last).to eq(@expected)
      }
    end
    
    it 'processes GOM creates' do
      @publisher.send_message 'gnp', {
        :uri =>"/dmx/node/values:2", 
        :create => {
          :attribute=>{
            :name=>"2",
            :value=>"5"
          }
        }
      } 
      @expected[1] = 5
      eventually {
        expect(subscriber.received_events.size).to eq(2)
        expect(subscriber.received_events.last).to eq(@expected)
      }
    end
    it 'processes GOM deletes' do
      @publisher.send_message 'gnp', {
        :uri =>"/dmx/node/values:16", 
        :delete => {
          :attribute=>{
            :name=>"16"
          }
        }
      } 
      @expected[15] = 0
      eventually {
        expect(subscriber.received_events.size).to eq(2)
        expect(subscriber.received_events.last).to eq(@expected)
      }
    end
  end

end
