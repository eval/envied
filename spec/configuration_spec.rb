RSpec.describe ENVied::Configuration do
  it { is_expected.to respond_to :variable }
  it { is_expected.to respond_to :enable_defaults! }
  it { is_expected.to respond_to :defaults_enabled? }

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
        variable :bar, default: 'bar'
      end

      expect(config.variables).to include ENVied::Variable.new(:bar, :string, default: 'bar')
    end
  end

  describe 'defaults' do
    it 'is disabled by default' do
      expect(subject.defaults_enabled?).to_not be
    end

    describe '#enable_defaults!' do
      it 'can be passed a value' do
        expect {
          subject.enable_defaults!(true)
        }.to change { subject.defaults_enabled? }
      end

      it 'can be passed a block' do
        expect {
          subject.enable_defaults! { true }
        }.to change { subject.defaults_enabled? }.to(true)
      end
    end
  end
end
