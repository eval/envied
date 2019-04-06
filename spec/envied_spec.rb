RSpec.describe ENVied do
  describe 'class' do
    subject { described_class }
    it { is_expected.to respond_to :require }
  end

  def reset_envied
    ENVied.instance_eval do
      @env = nil
      @config = nil
    end
  end

  context 'configured' do

    before do
      reset_envied
    end

    def set_ENV(env = {})
      stub_const("ENV", env)
    end

    def configure(**options, &block)
      @config = ENVied::Configuration.new(options, &block)
    end

    def configured_with(**hash)
      @config = ENVied::Configuration.new.tap do |config|
        hash.each do |name, type|
          config.variable(name, type)
        end
      end
    end

    def envied_require(*args, **options)
      options[:config] = @config || ENVied::Configuration.new # Prevent `Configuration.load` from being called
      ENVied.require(*args, **options)
    end

    it 'does respond to configured variables' do
      set_ENV('A' => '1')
      configured_with(A: :integer)
      envied_require

      expect(described_class).to respond_to :A
    end

    it 'does not respond to unconfigured variables' do
      set_ENV('A' => '1')
      configured_with
      envied_require

      expect(described_class).to_not respond_to :B
    end

    it 'sets ENVied.config' do
      set_ENV('A' => '1')
      configured_with(A: :integer)
      envied_require

      expect(ENVied.config).to be_instance_of(ENVied::Configuration)
    end

    context 'ENV contains not all configured variables' do
      before do
        set_ENV
        configured_with(A: :integer)
      end

      specify do
        expect {
          envied_require
        }.to raise_error(RuntimeError, 'The following environment variables should be set: A.')
      end
    end

    context 'ENV variables are not coercible' do
      before do
        set_ENV('A' => 'NaN', 'B' => 'invalid')
        configured_with(A: :integer, B: :boolean)
      end

      specify do
        expect {
          envied_require
        }.to raise_error(
          RuntimeError,
          'The following environment variables are not coercible: A with "NaN" (integer), B with "invalid" (boolean).'
        )
      end
    end

    context 'configuring' do
      it 'raises error when configuring variable of unknown type' do
        expect {
          configured_with(A: :fixnum)
        }.to raise_error(ArgumentError, ":fixnum is not a supported type. Should be one of #{ENVied::Coercer.supported_types}")
      end
    end

    # TODO: review needed, doesn't make sense?
    context 'bug: default value "false" is not coercible' do
      before do
        configure(enable_defaults: true) do
          variable :FORCE_SSL, :boolean, default: true
        end
      end

      specify do
        expect {
          envied_require
        }.not_to raise_error
      end
    end

    describe 'defaults' do
      describe 'assigning' do
        it 'sets a default value for ENV variable' do
          configure(enable_defaults: true) do
            variable :A, :integer, default: '1'
          end
          envied_require

          expect(described_class.A).to eq 1
        end

        it 'sets a default value from calling a proc for ENV variable' do
          configure(enable_defaults: true) do
            variable :A, :integer, default: proc { "1" }
          end
          envied_require

          expect(described_class.A).to eq 1
        end

        it 'ignores setting defaults if they are disabled' do
          set_ENV
          configure(enable_defaults: false) do
            variable :A, :integer, default: "1"
            variable :B, :integer, default: "1"
          end

          expect {
            envied_require
          }.to raise_error(RuntimeError, 'The following environment variables should be set: A, B.')
        end

        it 'ignores a default value if ENV variable is already provided' do
          set_ENV('A' => '2')
          configure(enable_defaults: true) do
            variable :A, :integer, default: "1"
          end
          envied_require

          expect(described_class.A).to eq 2
        end

        it 'can set a default value via a proc that references another ENV variable' do
          set_ENV('A' => '1')
          configure(enable_defaults: true) do
            variable :A, :integer
            variable :B, :integer, default: proc {|env| env.A * 2 }
          end
          envied_require

          expect(described_class.B).to eq 2
        end
      end
    end

    describe ".required?" do
      # TODO: change to always return boolean
      it 'returns true-ish if `ENVied.require` was called' do
        expect {
          envied_require
        }.to change { ENVied.required? }.from(nil).to(anything)
      end
    end

    describe "groups" do
      context 'a variable in a group' do
        before do
          set_ENV
          configure do
            variable :MORE

            group :foo do
              variable :BAR
            end
            group :moo do
              variable :BAT
            end
          end
        end

        it 'is required when requiring the groups passed as a delimited string' do
          expect {
            envied_require('foo,moo')
          }.to raise_error(RuntimeError, 'The following environment variables should be set: BAR, BAT.')
        end

        it 'is required when requiring the group' do
          [:foo, 'foo'].each do |group|
            expect {
              envied_require(group)
            }.to raise_error(RuntimeError, 'The following environment variables should be set: BAR.')
          end
        end

        it 'is not required when requiring another group' do
          [:bat, 'bat'].each do |group|
            expect {
              envied_require(group)
            }.to_not raise_error
          end
        end

        it 'will not define variables not part of the default group' do
          set_ENV('MORE' => 'yes')
          envied_require(:default)

          expect {
            described_class.BAR
          }.to raise_error(NoMethodError)
        end

        it 'takes ENV["ENVIED_GROUPS"] into account when nothing is passed to require' do
          set_ENV('ENVIED_GROUPS' => 'foo')
          expect {
            envied_require
          }.to raise_error(RuntimeError, 'The following environment variables should be set: BAR.')
        end

        it 'will define variables in the default group when nothing is passed to require' do
          set_ENV('MORE' => 'yes')
          envied_require

          expect(described_class.MORE).to eq 'yes'
        end

        it 'requires variables without a group when requiring the default group' do
          [:default, 'default'].each do |group|
            expect {
              envied_require(group)
            }.to raise_error(RuntimeError, 'The following environment variables should be set: MORE.')
          end
        end
      end

      context 'a variable in multiple groups' do
        before do
          set_ENV
          configure do
            variable :MORE

            group :foo, :moo do
              variable :BAR
            end
          end
        end

        it 'is required when requiring any of the groups' do
          expect {
            envied_require(:foo)
          }.to raise_error(RuntimeError, 'The following environment variables should be set: BAR.')

          expect {
            envied_require(:moo)
          }.to raise_error(RuntimeError, 'The following environment variables should be set: BAR.')
        end
      end

      describe 'Hashable' do
        before do
          set_ENV('FOO' => 'a=1&b=&c', 'BAR' => '')
          configure do
            variable :FOO, :hash
            variable :BAR, :hash
          end
          envied_require
        end

        it 'yields hash from string' do
          expect(ENVied.FOO).to eq({ 'a' => '1', 'b' => '', 'c' => nil })
        end

        it 'yields hash from an empty string' do
          expect(ENVied.BAR).to eq({})
        end

        context 'with defaults enabled' do
          before do
            set_ENV
            configure(enable_defaults: true) do
              variable :BAZ, :hash
            end
          end

          it 'has no default by default' do
            # fixes a bug where variables of type :Hash had a default even
            # when none was configured.
            expect { envied_require }.to raise_error(RuntimeError, 'The following environment variables should be set: BAZ.')
          end
        end
      end

      describe 'Arrayable' do
        before do
          set_ENV('MORE' => 'a, b, and\, c')
          configure do
            variable :MORE, :array
          end
          envied_require
        end

        it 'yields array from string' do
          expect(ENVied.MORE).to eq ['a',' b',' and, c']
        end
      end

      describe 'URIable' do
        before do
          set_ENV('SITE_URL' => 'https://www.google.com')
          configure do
            variable :SITE_URL, :uri
          end
          envied_require
        end

        it 'yields a URI from string' do
          expect(ENVied.SITE_URL).to be_a URI
          expect(ENVied.SITE_URL.scheme).to eq 'https'
          expect(ENVied.SITE_URL.host).to eq 'www.google.com'
        end
      end
    end
  end
end
