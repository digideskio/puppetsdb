$:.unshift File.expand_path("../lib", __FILE__)
require "puppetsdb/version"

Gem::Specification.new do |s|
  s.name        = 'puppetsdb'
  s.version     = PuppetSDB::VERSION
  s.summary     = "Puppet ENC script stored against Amazon's SimpleDB"
  s.description = "A simple interface to Puppet's ENC stored on Amazon's SimpleDB"
  s.authors     = ["Brian Wong"]
  s.email       = 'bwong114@gmail.com'
  s.files       = Dir['lib/puppetsdb.rb'] + Dir['lib/puppetsdb/*.rb'] + Dir["bin/puppetsdb"]
  s.executables << 'puppetsdb'
  s.homepage    = 'https://github.com/bwong114/puppetsdb'
  s.add_runtime_dependency 'subcommand'
  s.add_runtime_dependency 'aws-sdk'
end
