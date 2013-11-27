class TestPublisher
  include Celluloid
  include Celluloid::Notifications

  def send_message(target, payload)
    publish target, payload
  end
end
