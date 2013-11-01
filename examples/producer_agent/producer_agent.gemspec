# -*- encoding: utf-8 -*-

$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'producer_agent'
  gem.version       = '1.0.0' 
  gem.summary       = 'Gom Agents example actor'
  gem.description   = 'This example actor produces data for use by other actors'
  gem.authors       = ['artcom']
  gem.email         = 'info@artcom.de'
  gem.homepage      = 'http://www.artcom.de'
  
  gem.files         = Dir['lib/producer_agent/*']
  gem.require_paths = ['lib']
 
  gem.add_runtime_dependency('gom_agents')
end

