require 'envied/version'
require 'envied/cli'
require 'envied/env_proxy'
require 'envied/coercer'
require 'envied/variable'
require 'envied/configuration'

class ENVied
  class << self
    attr_reader :env, :config
  end

  def self.require(*args)
    env!(*args)
    error_on_missing_variables!
    error_on_uncoercible_variables!
  end

  def self.env!(*args)
    @env = begin
      options = args.last.is_a?(Hash) ? args.pop : {}
      config = options.fetch(:config) { Configuration.load }
      groups = required_groups(*args)
      EnvProxy.new(config, groups: groups)
    end
  end

  def self.error_on_missing_variables!
    names = env.missing_variables.map(&:name)
    raise "The following environment variables should be set: #{names * ', '}" if names.any?
  end

  def self.error_on_uncoercible_variables!
    errors = env.uncoercible_variables.map do |v|
      "%{name} ('%{value}' can't be coerced to %{type})" % {name: v.name, value: env.value_to_coerce(v), type: v.type }
    end
    raise "The following environment variables are not coercible: #{errors.join(", ")}" if errors.any?
  end

  def self.required_groups(*groups)
    result = groups.compact
    result.any? ? result.map(&:to_sym) : [:default]
  end

  def self.springify(&block)
    if spring_enabled?
      Spring.after_fork(&block)
    else
      block.call
    end
  end

  def self.spring_enabled?
    defined?(Spring) && Spring.respond_to?(:watcher)
  end

  def self.method_missing(method, *args, &block)
    respond_to_missing?(method) ? (env && env[method.to_s]) : super
  end

  def self.respond_to_missing?(method, include_private = false)
    (env && env.has_key?(method)) || super
  end
end
