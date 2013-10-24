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
    
    it 'emits correct dmx universe' do
        subscriber # trigger lazy 
        subject # trigger lazy
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
