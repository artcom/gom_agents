require 'spec_helper'

describe EnttecGomDaemon::GnpObserver do
    before(:each) do
      @subscriber = SimpleSubscriber.new 'dmx_values'
      subject.process_gnp :update, { "name" => "1", "value" => "255" }
    end

    let (:universe) {
      values = (Array.new 512, 0)
      values[0] = 255
      values
    }

    it 'emits correct dmx universe' do
      eventually {
        expect(@subscriber.received_events.size).to eq(1)
        expect(@subscriber.received_events).to eq([universe])
      }
    end

end
