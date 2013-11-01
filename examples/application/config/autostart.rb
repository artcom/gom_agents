# your App's autostart
# This is executed by gom_agents before run! is called. 
# Use this to require() any gems into your application
# and to add your actors to the App::Supervisor

require 'producer_agent'

module Gom::Agents

  def self.autostart
    App::Supervisor.supervise ::ExampleProducer, as: :example_producer  
  end

end
