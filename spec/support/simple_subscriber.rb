class SimpleSubscriber
  include Celluloid
  include Celluloid::Notifications
  
  attr_reader :received_events
  
  def initialize channel
    subscribe channel, :input
    @received_events = []
  end
  
  def input _, data
    @received_events << data
  end
end
