class ENVied::Variable
  attr_reader :name, :type, :group, :default

  def initialize(name, type, options = {})
    @name = name
    @type = type
    @group = options.fetch(:group, :default).to_sym
    @default = options[:default]
  end

  def present_in_env?
    ENV.has_key?(name.to_s)
  end

  def env_value
    ENV[name.to_s]
  end
end
