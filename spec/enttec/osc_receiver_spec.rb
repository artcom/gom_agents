require 'spec_helper'

describe EnttecGomDaemon::OscReceiver do
  let(:subscriber) { SimpleSubscriber.new 'dmx_updates' }

  subject { EnttecGomDaemon::OscReceiver.new port: nil }

  context 'when receiving an valid OSC packet' do
    before(:each) do
      subscriber
      subject.on_udp_dgram OSC::Message.new('/light/1/5', 3).encode
    end

    it 'publishes a DMX channel change' do
      eventually {
        expect(subscriber.received_events.size).to eq(1)
        expect(subscriber.received_events.last).to eq([{ channel: 5, value: 3 }])
      }
    end
  end
end
