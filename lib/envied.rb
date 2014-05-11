require 'virtus'

class ENVied
  class Configuration
    include Virtus.model

    def self.variable(name, type = :String, options = {})
      options = { strict: true }.merge(options)
      attribute(name, type, options)
    end
  end

  def self.configuration(&block)
    @configuration ||= Class.new(Configuration)
    @configuration.instance_eval(&block) if block_given?
    @configuration
  end
  class << self
    alias_method :configure, :configuration
  end

  def self.require!
    @instance = nil
    configured_variables_present_or_error!
    configured_variables_coercible_or_error!

    @instance = configuration.new(ENV.to_hash)
  end

  def self.configured_variables_present_or_error!
    if missing_variable_names.any?
      raise "Please set the following ENV-variables: #{missing_variable_names.sort.join(',')}"
    end
  end

  def self.configured_variables_coercible_or_error!
    if non_coercible_variables.any?
      single_error = "ENV['%{name}'] can't be coerced to %{type}"
      errors = non_coercible_variables.map do |v|
        var_type = v.type.to_s.split("::").last
        single_error % { name: v.name, type: var_type }
      end.join ","

      raise "The following ENV-variables are not coercible: #{errors}"
    end
  end

  # A list of all configured variable names.
  #
  # @example
  #   ENVied.configured_variable_names
  #   # => [:DATABASE_URL]
  #
  # @return [Array<Symbol>] the list of variable names
  def self.configured_variable_names
    configured_variables.map(&:name).map(&:to_sym)
  end

  def self.configured_variables
    configuration.attribute_set.dup
  end

  def self.provided_variable_names
    ENV.keys.map(&:to_sym)
  end

  def self.non_coercible_variables
    configured_variables.map do |a|
      begin
        a.coerce ENV[a.name.to_s]
        next
      rescue Virtus::CoercionError
        a
      end
    end.compact
  end

  def self.missing_variable_names
    configured_variable_names - provided_variable_names
  end

  def self.method_missing(method, *args, &block)
    respond_to_missing?(method) ? @instance.public_send(method, *args, &block) : super
  end

  def self.respond_to_missing?(method, include_private = false)
    @instance.respond_to?(method) || super
  end
end
