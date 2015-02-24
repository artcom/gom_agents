require 'spec_helper'
require 'chromatic'

describe Gom::Observer do

  let(:gom_uri) { 'http://192.168.56.101:3080' }
  let(:gom) { Gom::Client.new gom_uri }

  subject { Gom::Observer.new gom }

  before(:each) do
    @test_root = gom.create!('/tests')
    @test_attribute = "#{@test_root}:foo"
    @subscriber = TestSubscriber.new(subject)
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

  it 'retrieves changing values for child attributes on gnp_subscribe' do
    @subscriber.gnp_subscribe(@test_root)
    eventually { expect(@subscriber.last_gnp).to have_key(:initial) }

    gom.update(@test_attribute, 'foo')
    eventually { expect(@subscriber.last_gnp).to have_key(:create) }
    eventually { expect(@subscriber.last_gnp[:create][:attribute][:value]).to eq('foo') }
  end

  it 'allows re-subscription after unsubscription' do
    # subscribe and get initial value
    subscription = @subscriber.gnp_subscribe(@test_attribute)
    eventually { expect(@subscriber.last_gnp).to have_key(:initial) }
    eventually { expect(@subscriber.last_gnp[:initial][:attribute][:value]).to eq(nil) }

    # unsubscribe
    subscription.unsubscribe

    # subscribe new subscriber and get initial value
    subscriber2 = TestSubscriber.new(subject)
    subscriber2.gnp_subscribe(@test_attribute)
    eventually { expect(subscriber2.last_gnp).to have_key(:initial) }
    eventually { expect(subscriber2.last_gnp[:initial][:attribute][:value]).to eq(nil) }

    # update value
    gom.update(@test_attribute, 'foo')

    # get new value with second subscriber
    eventually { expect(subscriber2.last_gnp).to have_key(:create) }
    eventually { expect(subscriber2.last_gnp[:create][:attribute][:value]).to eq('foo') }

    # but not with the first one
    expect(@subscriber.last_gnp).to have_key(:initial)
    expect(@subscriber.last_gnp[:initial][:attribute][:value]).to eq(nil)
  end

  it 'supports convenient attribute subscription' do
    @subscriber.on_attribute(@test_attribute)
    eventually_expect_attribute(@test_attribute, :initial, nil)

    gom.update(@test_attribute, 'foo')
    eventually_expect_attribute(@test_attribute, :create, 'foo')

    gom.update(@test_attribute, 'bar')
    eventually_expect_attribute(@test_attribute, :update, 'bar')

    gom.destroy(@test_attribute)
    eventually_expect_attribute(@test_attribute, :delete, nil)
  end

  def eventually_expect_attribute(path, event, value)
    eventually { expect(@subscriber.last_path).to eq(path) }
    eventually { expect(@subscriber.last_event).to eq(event) }
    eventually { expect(@subscriber.last_value).to eq(value) }
  end
end
