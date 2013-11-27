require 'spec_helper'

describe Gom::Agents do

  specify { expect(subject).to respond_to(:version) }
  specify { expect(subject).to have_constant(:VERSION) }
  specify { expect(subject::VERSION).to eq(subject.version) }
  
end

describe Gom::Agents::App do
  subject { Gom::Agents::App }
  
  before(:each) do
    allow_message_expectations_on_nil
    allow(Gom::Client).to receive(:new).with('http://gom:345/')
    subject.parse ['http://gom:345/dmx/node']
  end

  it 'should initialize with GOM node path' do
    expect(subject.app_node).to eq('/dmx/node') 
  end

end
