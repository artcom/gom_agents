require 'spec_helper'

describe Rdmx::Dmx do

  subject { 
    allow(SerialPort).to receive(:new).with('/tmp/test', {
      'baud' => 115_200, 
      'data_bits' => 8, 
      'stop_bits' => 2, 
      'parity' => SerialPort::NONE
    })
    Rdmx::Dmx.new('/tmp/test') 
  }
  
  describe 'initialization' do
    it 'should initialize a serial port object on the given device' do
      expect(subject).to_not be_nil
    end
  end

  describe 'packet construction' do
    it 'should pad correctly' do
      expect(Rdmx::Dmx.packetize(1)).to eq(["\x7E", "\x06", "\x02", "\x00", "\x00", "\x01", "\xE7"])
    end

    it 'should work with byte arguments' do
      expect(lambda do
        Rdmx::Dmx.packetize("\x00")
      end).to_not raise_error
    end

    it 'should work with integer arguments' do
      expect(lambda do
        Rdmx::Dmx.packetize(0)
      end).to_not raise_error
    end
  end

  describe 'packet deconstruction' do
    it 'should remove padding' do
      expect(Rdmx::Dmx.depacketize(Rdmx::Dmx.packetize(1).join)).to eq([1])
    end
  end

  describe 'writing' do
    it 'should convert to a packet and write to the port' do
      allow_message_expectations_on_nil
      allow(subject.port).to receive(:write).with("\x7E\x06\x03\x00\x00\x01\x02\xE7")
      subject.write(1, 2)
    end
  end

  describe 'reading' do
    it 'should read from the port and convert from a DMX packet' do
      allow_message_expectations_on_nil
      allow(subject.port).to receive(:read).and_return("\x7E\x06\x03\x00\x00\x01\x02\xE7")
      expect(subject.read).to eq([1, 2])
    end
  end
end
