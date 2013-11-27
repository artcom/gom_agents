require 'spec_helper'
require 'chromatic'

describe Gom::Observer do

  let(:gom_uri) { 'http://192.168.56.101:3080' }
  let(:gom) { Gom::Client.new gom_uri }

  subject {
    Gom::Observer.new gom
  }

  before(:each) do
    @test_root = gom.create!('/tests')
    # puts "Using test root path '#{@test_root}'".yellow
    @subscriber = SimpleActor.new
  end

  after(:each) do
    gom.destroy @test_root
  end

  it 'retrieves initial values on gnp_subscribe' do
    @subscriber.wrapped_object.class.class_eval {
      attr_reader :initial_payload

      def test_subscribe(gom_observer, test_root)
        gom_observer.gnp_subscribe("#{test_root}:foo") { |gnp|
          @initial_payload = gnp
        }
      end
    }
    @subscriber.test_subscribe subject, @test_root
    eventually {
      expect(@subscriber.initial_payload).not_to be_nil
    }
  end

  it 'retrieves changing values on gnp_subscribe' do
    @subscriber.wrapped_object.class.class_eval {
      attr_reader :last_change

      def test_subscribe(gom_observer, test_root)
        gom_observer.gnp_subscribe("#{test_root}:foo") { |gnp|
          @last_change = gnp
        }
      end

      def test_update(gom, test_root)
        gom.update("#{test_root}:foo", 'bar')
      end
    }
    @subscriber.test_subscribe subject, @test_root
    eventually {
      expect(@subscriber.last_change).to have_key(:initial)
    }
    @subscriber.test_update gom, @test_root
    eventually {
      expect(@subscriber.last_change).to have_key(:create)
    }
  end

end
