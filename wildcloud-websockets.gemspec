lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'wildcloud/websockets/version'

Gem::Specification.new do |s|
  s.name        = 'wildcloud-websockets'
  s.version     = Wildcloud::Websockets::VERSION
  s.platform    = Gem::Platform::JAVA
  s.authors     = ['Marek Jelen']
  s.email       = ['marek@jelen.biz']
  s.homepage    = 'http://github.com/wildcloud'
  s.summary     = 'Websockets service for Wildcloud'
  s.description = 'Service providing websockets to applications deployed in Wildcloud platform'
  s.license     = 'Apache2'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'json', '1.6.5'
  s.add_dependency 'hot_bunnies', '1.3.4'
  s.add_dependency 'multi_json', '1.0.4'
  s.add_dependency 'httparty', '0.8.1'
  s.add_dependency 'sinatra', '1.3.2'

  s.files        = Dir.glob('{bin,lib,ext}/**/*') + %w(LICENSE README.md CHANGELOG.md)
  s.executables  = %w(wildcloud-websockets)
  s.require_path = 'lib'
end