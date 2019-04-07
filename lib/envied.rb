require 'envied/version'
require 'envied/cli'
require 'envied/env_proxy'
require 'envied/coercer'
require 'envied/coercer/envied_string'
require 'envied/variable'
require 'envied/configuration'
require 'envied/errors/missing_variables_error'
require 'envied/errors/incoercible_variables_error'

class ENVied
  class << self
    attr_reader :env, :config

    def required?
      !env.nil?
    end

    private

    def env!(requested_groups, **options)
      @config = options.fetch(:config) { Configuration.load }
      @env = EnvProxy.new(@config, groups: required_groups(*requested_groups))
    end

    def required_groups(*groups)
      splitter = ->(group){ group.is_a?(String) ? group.split(/ *, */) : group }
      result = groups.compact.map(&splitter).flatten
      result.any? ? result.map(&:to_sym) : [:default]
    end

    def error_on_missing_variables!
      if env.missing_variables.any?
        raise MissingVariablesError.with(env.missing_variables.map(&:name))
      end
    end

    def error_on_incoercible_variables!
      if env.incoercible_variables.any?
        variables = env.incoercible_variables.map do |v|
          format("%{name} with %{value} (%{type})", name: v.name, value: env.value_to_coerce(v).inspect, type: v.type)
        end
        raise IncoercibleVariablesError.with(variables)
      end
    end

    def ensure_spring_after_fork_require(args, **options)
      if spring_enabled? && !options[:via_spring]
        Spring.after_fork { ENVied.require(args, options.merge(via_spring: true)) }
      end
    end

    def spring_enabled?
      defined?(Spring) && Spring.respond_to?(:watcher)
    end
  end

  def self.require(*args, **options)
    requested_groups = (args && !args.empty?) ? args : ENV['ENVIED_GROUPS']
    env!(requested_groups, options)
    error_on_missing_variables!
    error_on_incoercible_variables!
    ensure_spring_after_fork_require(args, options)
  end

  def self.springify(&block)
    if defined?(ActiveSupport::Deprecation.warn) && !required?
      ActiveSupport::Deprecation.warn(<<~MSG)
        It's no longer recommended to `ENVied.require` within ENVied.springify's
        block. Please re-run `envied init:rails` to upgrade.
      MSG
    end
    if spring_enabled?
      Spring.after_fork(&block)
    else
      block.call
    end
  end

  def self.method_missing(method, *args, &block)
    if respond_to_missing?(method)
      env[method.to_s]
    else
      super
    end
  end

  def self.respond_to_missing?(method, include_private = false)
    (env && env.has_key?(method)) || super
  end
end
