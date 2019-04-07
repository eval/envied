class ENVied::IncoercibleVariablesError < RuntimeError

  def self.with(variables)
    msg = "The following environment variables are not coercible: #{variables.join(", ")}."
    msg << "\nPlease make sure to stop Spring before retrying." if defined?(::Spring)
    new(msg)
  end

end
