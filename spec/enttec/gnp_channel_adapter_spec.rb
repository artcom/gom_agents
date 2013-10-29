require 'spec_helper'

describe EnttecGomDaemon::GnpDmxAdapter do
  subject { EnttecGomDaemon::GnpDmxAdapter }

  let (:initial_retrieve) {
    {
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
  }

  let (:create_notification) {
    {
      :uri =>"/dmx/node/values:2", 
      :create => {
        :attribute=>{
          :name=>"2",
          :value=>"5"
        }
      }
    } 
  }   

  let (:update_notification) {
    {
      :uri =>"/dmx/node/values:1", 
      :update => {
        :attribute=>{
          :name=>"1",
          :value=>"255"
        }
      }
    } 
  }

  let (:delete_notification) {
    {
      :uri =>"/dmx/node/values:16", 
      :delete => {
        :attribute=>{
          :name=>"16"
        }
      }
    } 
  }

  context "when receiving a GNP" do

    it "should process initial retrieves" do
      expect(subject.on_gnp initial_retrieve).to eq(
        [{:channel=>"1", :value=>"1"}, {:channel=>"17", :value=>"23"}, {:channel=>"245", :value=>"177"}]
      ) 
    end
    
    it "should process creates" do
      expect(subject.on_gnp create_notification).to eq(
        [{:channel=>"2", :value=>"5"}]
      ) 
    end
    
    it "should process updates" do
      expect(subject.on_gnp update_notification).to eq(
        [{:channel=>"1", :value=>"255"}]
      ) 
    end
    
    it "should process deletes" do
      expect(subject.on_gnp delete_notification).to eq(
        [{:channel=>"16", :value=>nil}]
      ) 
    end
  end

end
