class SimpleSubscriber
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Logger

  attr_reader :last_gnp

  def initialize(gom_observer)
    @gom_observer = gom_observer
  end

  def subscribe(path)
    @gom_observer.gnp_subscribe(path) do |gnp|
      @last_gnp = gnp
    end
  end
end
