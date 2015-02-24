class TestSubscriber
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Logger

  attr_reader :last_gnp, :last_value, :last_event, :last_path

  def initialize(gom_observer)
    @gom_observer = gom_observer
  end

  def gnp_subscribe(path)
    @gom_observer.gnp_subscribe(path) do |gnp|
      @last_gnp = gnp
    end
  end

  def on_attribute(attribute_path)
    @gom_observer.on_attribute(attribute_path) do |value, event, path|
      @last_value = value
      @last_event = event
      @last_path = path
    end
  end
end
