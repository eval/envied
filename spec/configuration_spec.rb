require 'spec_helper'

describe ENVied::Configuration do
  it { is_expected.to respond_to :variable }

  describe '#variable' do
    def with_envfile(&block)
      @config = described_class.new(&block)
    end
    attr_reader :config

    it 'results in an added variable' do
      with_envfile do
        variable :foo, :boolean
      end

      expect(config.variables).to include ENVied::Variable.new(:foo, :boolean)
    end

    it 'sets string as type when no type is given' do
      with_envfile do
        variable :bar
      end

      expect(config.variables).to include ENVied::Variable.new(:bar, :string)
    end
  end
end
