require "virtus"

module ENVied
  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      include Virtus.model
    end
  end

  module ClassMethods
    def variable(*args)
      attribute(*args)
    end
  end
end
