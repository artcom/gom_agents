# -*- encoding: utf-8 -*-

$:.push File.expand_path('../lib', __FILE__)
require 'enttec_gom_daemon/version'

Gem::Specification.new do |gem|
  gem.name          = 'enttec-gom-daemon'
  gem.version       = EnttecGomDaemon::VERSION
  gem.summary       = 'enttec gom gateway'
  gem.description   = 'celluloid based gateway to enttec DMX adapter'
  gem.authors       = ['artcom']
  gem.email         = 'info@artcom.de'
  gem.homepage      = 'http://www.artcom.de'
  
  gem.files         = Dir['lib/enttec_gom_daemon/*']
  gem.require_paths = ['lib']
 
  gem.bindir        = 'bin'
  gem.executables   << 'enttec-gom-daemon'
  gem.add_runtime_dependency('serialport')
  gem.add_runtime_dependency('nokogiri')
  gem.add_runtime_dependency('hybridgroup-celluloid-websocket-client')
  gem.add_runtime_dependency('gom-client')
  gem.add_runtime_dependency('reel')
  gem.add_runtime_dependency('celluloid-io')
  gem.add_runtime_dependency('osc-ruby')
  gem.add_runtime_dependency('chromatic')

  gem.add_development_dependency('debugger')
  gem.add_development_dependency('guard')
  gem.add_development_dependency('guard-rspec')
  gem.add_development_dependency('guard-bundler')
  gem.add_development_dependency('guard-rubocop')
  gem.add_development_dependency('rubocop')
end

