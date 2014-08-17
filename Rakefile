require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |s|
  s.ruby_opts = %w(-w)
end

desc "Run the specs"
task default: :spec
