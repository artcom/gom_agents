class TestPublisher
  
  include Celluloid
  include Celluloid::Notifications 
  
  def send_command target, payload
    publish target, payload
  end
  
end
