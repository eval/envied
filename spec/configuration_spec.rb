RSpec.describe ENVied::Configuration do
  it { is_expected.to respond_to :variable }
  it { is_expected.to respond_to :group }
  it { is_expected.to respond_to :enable_defaults! }
  it { is_expected.to respond_to :defaults_enabled? }

  def with_envfile(**options, &block)
    @config = ENVied::Configuration.new(options, &block)
  end
  attr_reader :config

  describe 'variables' do
    it 'results in an added variable' do
      with_envfile do
        variable :foo, :boolean
      end

      expect(config.variables).to include ENVied::Variable.new(:foo, :boolean, group: :default)
    end

    it 'sets string as default type when no type is given' do
      with_envfile do
        variable :bar
      end

      expect(config.variables).to include ENVied::Variable.new(:bar, :string, default: nil, group: :default)
    end

    it 'sets a default value when specified' do
      with_envfile do
        variable :bar, default: 'bar'
      end

      expect(config.variables).to include ENVied::Variable.new(:bar, :string, default: 'bar', group: :default)
    end

    it 'sets specific group for variable' do
      with_envfile do
        group :production do
          variable :SECRET_KEY_BASE
        end
      end

      expect(config.variables).to include ENVied::Variable.new(:SECRET_KEY_BASE, :string, group: :production)
    end
  end

  describe 'defaults' do
    it 'is disabled by default' do
      expect(subject.defaults_enabled?).to eq false
    end

    it 'can be enabled with an ENV variable' do
      allow(ENV).to receive(:[]).with("ENVIED_ENABLE_DEFAULTS").and_return("true")
      expect(subject.defaults_enabled?).to eq true
    end

    it 'can be enabled through a config option' do
      with_envfile(enable_defaults: true) { }

      expect(config.defaults_enabled?).to eq true
    end

    describe '#enable_defaults!' do
      it 'can be enabled in a block by calling `enable_defaults!`' do
        with_envfile do
          enable_defaults!
        end

        expect(config.defaults_enabled?).to eq true
      end

      it 'can be enabled by calling `enable_defaults!` with a Proc' do
        with_envfile do
          enable_defaults! { true }
        end

        expect(config.defaults_enabled?).to eq true
      end

      it 'defaults to true with no arguments' do
        expect {
          subject.enable_defaults!
        }.to change { subject.defaults_enabled? }.from(false).to(true)
      end

      it 'can be passed a boolean value' do
        expect {
          subject.enable_defaults!(true)
        }.to change { subject.defaults_enabled? }.from(false).to(true)
      end

      it 'can be passed a block' do
        expect {
          subject.enable_defaults! { true }
        }.to change { subject.defaults_enabled? }.from(false).to(true)
      end
    end
  end
end
