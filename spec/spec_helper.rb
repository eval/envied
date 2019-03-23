require 'rubygems'
require 'bundler'
Bundler.setup

$:.unshift File.expand_path("../../lib", __FILE__)
require 'envied'

RSpec.configure do |config| 
  config.disable_monkey_patching!
end
