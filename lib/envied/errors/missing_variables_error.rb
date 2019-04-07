class ENVied::MissingVariablesError < RuntimeError

  def self.with(variables)
    msg = "The following environment variables should be set: #{variables.join(', ')}."
    msg << "\nPlease make sure to stop Spring before retrying." if defined?(::Spring)
    new(msg)
  end

end
