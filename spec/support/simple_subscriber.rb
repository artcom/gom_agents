class SimpleSubscriber
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Logger

  attr_reader :last_gnp

  def initialize(gom_observer)
    @gom_observer = gom_observer
  end

  def gnp_subscribe(path)
    @gom_observer.gnp_subscribe(path) do |gnp|
      @last_gnp = gnp
    end
  end

  def gnp_unsubscribe(subscription)
    @gom_observer.gnp_unsubscribe(subscription)
  end
end
