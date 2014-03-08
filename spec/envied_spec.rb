require 'spec_helper'

class AppConfig
  include ENVied
end

describe AppConfig, 'A class including ENVied' do
  subject { described_class }

  it { should respond_to :variable }
  it { should respond_to :attribute }

  describe '::variable' do
    def variable(name)
      described_class.variable name
    end

    it 'make the instance respond_to it' do
      variable :a
      expect(described_class.new).to respond_to :a
    end
  end
end
