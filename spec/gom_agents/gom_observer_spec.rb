require 'spec_helper'
require 'chromatic'

describe Gom::Observer do

  let(:gom_uri) { 'http://192.168.56.101:3080' }
  let(:gom) { Gom::Client.new gom_uri }

  subject { Gom::Observer.new gom }

  before(:each) do
    @test_root = gom.create!('/tests')
    @test_attribute = "#{@test_root}:foo"
    @subscriber = SimpleSubscriber.new(subject)
  end

  after(:each) do
    gom.destroy @test_root
  end

  it 'retrieves initial values on gnp_subscribe' do
    @subscriber.gnp_subscribe(@test_attribute)
    eventually { expect(@subscriber.last_gnp).not_to be_nil }
  end

  it 'retrieves changing values on gnp_subscribe' do
    @subscriber.gnp_subscribe(@test_attribute)
    eventually { expect(@subscriber.last_gnp).to have_key(:initial) }
    eventually { expect(@subscriber.last_gnp[:initial][:attribute][:value]).to eq(nil) }

    gom.update(@test_attribute, 'bar')
    eventually { expect(@subscriber.last_gnp).to have_key(:create) }
    eventually { expect(@subscriber.last_gnp[:create][:attribute][:value]).to eq('bar') }
  end

end
