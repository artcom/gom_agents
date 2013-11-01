class ExampleProducer
  include Celluloid
  include Celluloid::Logger

  def initialize
    info "#{self.class} started"
  end
end
