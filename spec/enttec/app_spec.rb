require 'spec_helper'

describe EnttecGomDaemon do

  specify { expect(subject).to respond_to(:version) }
  specify { expect(subject).to have_constant(:VERSION) }
  specify { expect(subject::VERSION).to eq(subject.version) }
  
end

describe EnttecGomDaemon::App do
  subject { EnttecGomDaemon::App.instance }
  
  before(:each) do
    subject.parse ['http://gom:345/dmx/node']
  end

  specify "should initialize with GOM node path" do
      expect(subject.path).to eq('/dmx/node') 
  end
end
