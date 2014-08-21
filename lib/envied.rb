require 'envied/version'
require 'envied/cli'
require 'virtus'

class ENVied
  module Hashable
    def to_hash
      require 'rack/utils'
      ::Rack::Utils.parse_nested_query(self)
    end
  end

  module Arrayable
    def to_a
      self.split(/(?<!\\), ?/).map{|i| i.gsub(/\\,/,',') }
    end
  end

  class Configuration
    include Virtus.model

    def self.variable(name, type = :String, options = {})
      options = { default: nil, strict: true, group: self.current_group }.merge(options)
      type = Array if type == :Array
      attribute(name, type, options)
    end

    def self.group(name, &block)
      self.current_group = name.to_sym
      yield
    ensure
      self.current_group = :default
    end

    def self.enable_defaults
      (@enable_defaults ||= false).respond_to?(:call) ?
        @enable_defaults.call :
        @enable_defaults
    end

    def self.enable_defaults!(value = nil, &block)
      value ||= block if block_given?
      @enable_defaults = value
    end

    class << self
      alias_method :defaults_enabled?, :enable_defaults
      alias_method :enable_defaults=, :enable_defaults!
      attr_writer :current_group
    end

    def self.current_group
      @current_group ||= :default
    end
  end

  def self.configuration(options = {}, &block)
    if block_given?
      @configuration = build_configuration(&block).tap do |c|
        options.each {|k, v| c.public_send("#{k}=", v) }
      end
    end
    @configuration ||= build_configuration
  end

  def self.configure(options = {}, &block)
    deprecation_warning "ENVied.configure will be deprecated. Please generate an Envfile instead (see the envied command)."
    configuration(options, &block)
  end

  class << self
    attr_accessor :required_groups
  end

  def self.build_configuration(&block)
    Class.new(Configuration).tap do |c|
      c.instance_eval(&block) if block_given?
    end
  end

  def self.require(*groups)
    groups.compact!
    @instance = nil
    if groups.any?
      self.required_groups = groups.map(&:to_sym)
    else
      self.required_groups = [:default]
    end
    ensure_configured!
    error_on_missing_variables!
    error_on_uncoercible_variables!

    _required_variables = required_variables
    group_configuration = build_configuration do
      _required_variables.each do |v|
        @attribute_set << v
      end
    end
    @instance = group_configuration.new(env)
  end

  def self.springified_require(*args)
    if defined?(Spring) && Spring.respond_to?(:watcher)
      Spring.after_fork { ENVied.require(*args) }
    else
      self.require(*args)
    end
  end

  def self.ensure_configured!
    # Backward compat: load Envfile only when it's present
    configure_via_envfile if envfile_exist?
  end

  def self.envfile
    File.expand_path('Envfile')
  end

  def self.envfile_exist?
    File.exist?(envfile)
  end

  def self.configure_via_envfile
    configuration { eval(File.read(ENVied.envfile)) }
  end

  def self.error_on_missing_variables!
    if missing_variable_names.any?
      raise "Please set the following ENV-variables: #{missing_variable_names.sort.join(',')}"
    end
  end

  def self.error_on_uncoercible_variables!
    # TODO default values should have defined type
    if non_coercible_variables.any?
      single_error = "ENV['%{name}'] ('%{value}' can't be coerced to %{type})"
      errors = non_coercible_variables.map do |v|
        var_type = v.type.to_s.split("::").last
        single_error % { name: v.name, value: env_value_or_default(v), type: var_type }
      end.join ", "

      raise "Some ENV-variables are not coercible: #{errors}"
    end
  end

  def self.env_value(variable)
    env[variable.name.to_s]
  end

  def self.env
    @env ||= begin
      Hash[ENV.to_hash.map {|k,v| [k, v.dup.extend(Hashable, Arrayable)] }]
    end
  end

  def self.env_value_or_default(variable)
    env_value(variable) || default_value(variable)
  end

  # Yields the assigned default for the variable.
  # When defaults are disabled, nil is returned.
  def self.default_value(variable)
    defaults_enabled? ? variable.default_value.value : nil
  end

  # A list of all configured variable names.
  #
  # @example
  #   ENVied.required_variable_names
  #   # => [:DATABASE_URL]
  #
  # @return [Array<Symbol>] the list of variable names
  def self.required_variable_names
    required_variables.map(&:name).map(&:to_sym)
  end

  def self.required_variables
    from_required_group = ->(var){ self.required_groups.include?(var.options[:group]) }
    configured_variables.to_a.keep_if(&from_required_group)
  end

  def self.configured_variables
    configuration.attribute_set.dup#.to_a.keep_if(&var_from_required_group)
  end

  def self.provided_variable_names
    ENV.keys.map(&:to_sym)
  end

  def self.non_coercible_variables
    required_variables.reject(&method(:variable_coercible?))
  end

  def self.variable_coercible?(variable)
    var_value = env_value_or_default(variable)
    return true if var_value.respond_to?(:call)

    !variable.coerce(var_value).nil?
  rescue Virtus::CoercionError
    return false
  end

  def self.missing_variable_names
    unprovided = required_variable_names - provided_variable_names
    unprovided -= names_of_required_variables_with_defaults if defaults_enabled?
    unprovided
  end

  def self.names_of_required_variables_with_defaults
    required_variables_with_defaults.map(&:name).map(&:to_sym)
  end

  def self.required_variables_with_defaults
    required_variables.map do |v|
      v unless v.default_value.value.nil?
    end.compact
  end

  def self.defaults_enabled?
    configuration.enable_defaults
  end

  def self.method_missing(method, *args, &block)
    respond_to_missing?(method) ? @instance.public_send(method, *args, &block) : super
  end

  def self.respond_to_missing?(method, include_private = false)
    @instance.respond_to?(method) || super
  end

  def self.deprecation_warning(msg)
    puts "DEPRECATION WARNING: #{msg}"
  end
end
