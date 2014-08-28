# 
class ENVied::Configuration
  attr_reader :groups, :coercer

  def initialize(options = {})
    @groups = options.fetch(:groups, [])
    @coercer = options.fetch(:coercer, ENVied::Coercer.new)
  end

  def self.load(*groups)
    new(groups: Array(groups).map(&:to_sym)).tap do |v|
      v.instance_eval(File.read(File.expand_path('Envfile')))
    end
  end

  def variable(name, type, options = {})
    options[:group] = @current_group if @current_group
    ENVied::Variable.new(name, type, options).tap do |v|
      variables << v if include_variable?(v)
    end
  end

  def group(name, &block)
    @current_group = name.to_sym
    yield
  ensure
    @current_group = nil
  end

  def variables
    @variables ||= []
  end

  def value_of(name)
    var = variable_by_name.fetch!(name.to_sym)
    coerce(var)
  end

  def coerce(var)
    coercer.coerce(var.env_value, var.type)
  end

  def variable_by_name
    Hash[@variables.map {|v| [v.name, v] }]
  end

  def missing_variables
    variables.reject(&:present_in_env?)
  end

  def uncoercible_variables
    coercible = ->(v){ coercer.coercible?(v.env_value, v.type) }
    variables.reject(&coercible)
  end

  def include_variable?(var)
    !groups.any? || groups.include?(var.group)
  end
end
