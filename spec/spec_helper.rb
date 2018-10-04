require 'rubygems'
require 'bundler'
Bundler.setup

$:.unshift File.expand_path("../../lib", __FILE__)
require 'envied'

RSpec.configure do |config|
  config.before do
    ENVied::Coercer.custom_types.clear
  end
end
