# -*- encoding: utf-8 -*-

$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'gom_agents/version'

Gem::Specification.new do |gem|
  gem.name          = 'gom_agents'
  gem.version       = Gom::Agents::VERSION
  gem.summary       = 'Celluloid Actor based Agents'
  gem.description   = 'celluloid based agents framework'
  gem.authors       = ['artcom']
  gem.email         = 'info@artcom.de'
  gem.homepage      = 'http://www.artcom.de'
  gem.required_ruby_version = '>= 1.9.3'

  gem.requirements << 'A gom instance (or compatible equivalent)'
  
  gem.files         = Dir['lib/gom_agents/*']
  gem.require_paths = ['lib']
 
  gem.bindir        = 'bin'
  gem.executables   << 'agents'
  gem.add_runtime_dependency('hybridgroup-celluloid-websocket-client')
  gem.add_runtime_dependency('gom-client')
  gem.add_runtime_dependency('reel')
  gem.add_runtime_dependency('celluloid-io')
  gem.add_runtime_dependency('chromatic')

  gem.add_development_dependency('debugger')
  gem.add_development_dependency('guard')
  gem.add_development_dependency('guard-rspec')
  gem.add_development_dependency('guard-bundler')
  gem.add_development_dependency('guard-rubocop')
  gem.add_development_dependency('rubocop')
end

