require 'spec_helper'

describe ENVied::Variable do
  def variable(*args)
    described_class.new(*args)
  end

  def set_env(env)
    stub_const("ENV", env)
  end

  describe 'an instance' do
    subject { variable(:A, :string) }
  end
end
