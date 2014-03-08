class ENVied
  VERSION = "0.0.2"
  module Configurable
    require 'virtus'

    class EnvMissing < StandardError;end
    class EnvWrongType < StandardError;end

    def self.included(base)
      base.class_eval do
        include Virtus.model
      end
      base.extend ClassMethods
    end

    module ClassMethods
      # Creates an instance of Configuration.
      #
      # Will raise EnvMissing for variables Configuration defined
      # but are missing from env.
      #
      # Will raise EnvWrongType for variables that can't be coerced to the
      # type defined in Configuration.
      #
      # @param env [Hash] the env
      def parse_env(env)
        atts = attribute_set.map(&:name).each_with_object({}) do |name, result|
          @current_att = name
          unless result[name] = env[name.to_s] || env[name.to_s.upcase]
            raise EnvMissing, "Please provide ENV['#{name.to_s.upcase}']"
          end
        end
        new(atts)
      rescue Virtus::CoercionError => e
        configured_type = attribute_set[@current_att].options[:primitive]
        raise EnvWrongType,
          "ENV['#{@current_att.to_s.upcase}'] should be of type %s" % configured_type
      end

      def variable(name, type = String, options = {})
        attribute name, type, { strict: true }.merge(options)
      end
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure(&block)
    @configuration = Class.new { include Configurable }.tap(&block)
    # or define this thing as ENVied::Configuration? prolly not threadsafe
  ensure
    @instance = nil
  end

  def self.instance
    @instance ||= @configuration.parse_env(ENV.to_hash)
  end
  class << self
    alias_method :require!, :instance
  end

  def self.[](key)
    instance.attributes[key]
    #instance[key] # will raise and complain that <class <>> doesn't response; better?
  end

  def self.method_missing(method, *args, &block)
    respond_to_missing?(method) ? instance.public_send(method, *args, &block) : super
  end

  def self.respond_to_missing?(method, include_private = false)
    instance.attributes.key?(method) || super
  end
end
