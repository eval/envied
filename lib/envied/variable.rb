class ENVied::Variable
  attr_reader :name, :type, :group, :default

  def initialize(name, type, options = {})
    @name = name.to_sym
    @type = type.to_sym
    @group = options.fetch(:group, :default).to_sym
    @default = options[:default]
  end
end
