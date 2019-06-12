RSpec.describe ENVied::Configuration do
  it { is_expected.to respond_to :variable }
  it { is_expected.to respond_to :group }

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

    it 'sets the same variable for multiple groups' do
      with_envfile do
        group :development, :test do
          variable :DISABLE_PRY, :boolean, default: 'false'
        end
      end

      expect(config.variables).to eq [
        ENVied::Variable.new(:DISABLE_PRY, :boolean, default: 'false', group: :development),
        ENVied::Variable.new(:DISABLE_PRY, :boolean, default: 'false', group: :test)
      ]
    end
  end
end
