# encoding: utf-8

require 'celluloid'
require 'celluloid/io'

module EnttecGomDaemon
  
  require 'enttec_gom_daemon/version'

  require 'enttec_gom_daemon/gnp_observer'
  require 'enttec_gom_daemon/dmx_universe'
  require 'enttec_gom_daemon/app'
  
  UDP_SENSOR_PORT = 3333
  UDP_PACKAGE_RECEIVE_SIZE = 4096 # in bytes
  
  WEB_SERVER_PORT = 1234
  
end
