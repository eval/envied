RSpec.describe ENVied do
  describe 'class' do
    subject { described_class }

    it { is_expected.to respond_to :require }
  end

  describe 'responding to methods that are variables' do
  end

  before do
    reset_env
    reset_envied_config
    reset_configuration
  end

  def reset_configuration
    @config = ENVied::Configuration.new
  end

  def reset_env
    ENVied.instance_eval { @env = nil }
  end

  def reset_envied_config
    ENVied.instance_eval { @config = nil }
  end

  context 'configured' do

    def unconfigured
      configured_with
      self
    end

    def config
      @config
    end

    def configure(options = {}, &block)
      @config = ENVied::Configuration.new(options, &block)
      self
    end

    def configured_with(hash = {})
      @config = ENVied::Configuration.new.tap do |c|
        hash.each do |name, type|
          c.variable(name, *type)
        end
      end
      self
    end

    def and_ENV(env = {})
      stub_const("ENV", env)
      described_class
    end

    def and_no_ENV
      and_ENV
    end

    def envied_require(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:config] = options[:config] || config

      ENVied.require(*args, options)
    end

    it 'responds to configured variables' do
      configured_with(a: :integer).and_ENV({'a' => '1'})
      envied_require

      expect(described_class).to respond_to :a
    end

    it 'responds not to unconfigured variables' do
      unconfigured.and_ENV({'A' => '1'})
      envied_require

      expect(described_class).to_not respond_to :B
    end

    it 'sets ENVied.config' do
      configured_with(a: :integer).and_ENV({'a' => '1'})
      envied_require

      expect(ENVied.config).to_not be(nil)
    end

    context 'ENV contains not all configured variables' do
      before { configured_with(a: :integer).and_no_ENV }

      specify do
        expect {
          envied_require
        }.to raise_error(RuntimeError, 'The following environment variables should be set: a.')
      end
    end

    context 'ENV variables are not coercible' do
      before { configured_with(A: :integer).and_ENV('A' => 'NaN') }

      specify do
        expect {
          envied_require
        }.to raise_error(/A \('NaN' can't be coerced to integer/)
      end
    end

    context 'configuring' do
      it 'raises error when configuring variable of unknown type' do
        expect {
          configured_with(A: :fixnum)
        }.to raise_error(ArgumentError, /Variable type \(of A\) should be one of \[/)
      end
    end

    context 'bug: default value "false" is not coercible' do
      before {
        configure(enable_defaults: true) do
          variable :FORCE_SSL, :boolean, default: true
        end
      }

      specify do
        expect {
          envied_require
        }.not_to raise_error
      end
    end

    describe 'defaults' do
      describe 'setting' do
        subject { config }

        it 'is disabled by default' do
          expect(subject.defaults_enabled?).to_not be
        end

        it 'yields ENV["ENVIED_ENABLE_DEFAULTS"] if not set otherwise' do
          stub_const("ENV", {'ENVIED_ENABLE_DEFAULTS' => '1'})
          configure

          expect(subject.defaults_enabled?).to be
        end

        it 'can be enabled via #configure' do
          configure(enable_defaults: true){ }

          expect(subject.defaults_enabled?).to be
        end

        it 'can be enabled via a configure-block' do
          configure { self.enable_defaults! }

          expect(subject.defaults_enabled?).to be
        end

        it 'can be assigned a Proc' do
          configure { self.enable_defaults! { true } }

          expect(subject.defaults_enabled?).to be
        end
      end

      describe 'assigning' do
        it 'can be a value' do
          configure(enable_defaults: true) do
            variable :A, :integer, default: '1'
          end
          envied_require

          expect(described_class.A).to eq 1
        end

        it 'can be a Proc' do
          configure(enable_defaults: true) do
            variable :A, :integer, default: proc { "1" }
          end
          envied_require

          expect(described_class.A).to eq 1
        end

        it 'is ignored if defaults are disabled' do
          configure(enable_defaults: false) do
            variable :A, :integer, default: "1"
          end.and_no_ENV

          expect {
            envied_require
          }.to raise_error(RuntimeError, 'The following environment variables should be set: A.')
        end

        it 'is ignored if ENV is provided' do
          configure(enable_defaults: true) do
            variable :A, :integer, default: "1"
          end.and_ENV('A' => '2')
          envied_require

          expect(described_class.A).to eq 2
        end

        it 'can be defined in terms of other variables' do
          configure(enable_defaults: true) do
            variable :A, :integer
            variable :B, :integer, default: proc {|env| env.A * 2 }
          end.and_ENV('A' => '1')
          envied_require

          expect(described_class.B).to eq 2
        end
      end
    end

    describe "::required?" do
      it 'yields true-ish when ::require is called' do
        expect {
          envied_require
        }.to change { ENVied.required? }.from(nil).to(anything)
      end
    end

    describe "groups" do
      describe 'requiring' do

        it 'yields :default when nothing passed to require' do
          envied_require
          expect(ENVied.env.groups).to eq [:default]
        end

        it 'takes ENV["ENVIED_GROUPS"] into account when nothing passed to require' do
          and_ENV('ENVIED_GROUPS' => 'baz')
          envied_require
          expect(ENVied.env.groups).to eq [:baz]
        end

        it 'yields groupnames passed to it as string' do
          envied_require('bar')
          expect(ENVied.env.groups).to eq [:bar]
        end

        it 'yields groupnames passed to it as symbols' do
          envied_require(:foo)
          expect(ENVied.env.groups).to eq [:foo]
        end

        it 'yields the groups passed via a string with groupnames' do
          envied_require('foo,bar')
          expect(ENVied.env.groups).to eq [:foo, :bar]
        end
      end

      context 'a variable in a group' do
        before do
          configure do
            variable :moar

            group :foo do
              variable :bar
            end
          end.and_no_ENV
        end

        it 'is required when requiring the group' do
          expect {
            envied_require(:foo)
          }.to raise_error(/bar/)
        end

        it 'is not required when requiring another group' do
          expect {
            envied_require(:bat)
          }.to_not raise_error
        end

        it 'wont define non-required variables on ENVied' do
          stub_const("ENV", {'moar' => 'yes'})
          envied_require(:default)

          expect {
            described_class.bar
          }.to raise_error(NoMethodError)
        end

        it 'requires variables without a group when requiring the default group' do
          [:default, 'default'].each do |groups|
            expect {
              envied_require(*groups)
            }.to raise_error(/moar/)
          end
        end
      end

      context 'a variable in multiple groups' do
        before do
          configure do
            variable :moar

            group :foo, :moo do
              variable :bar
            end
          end.and_no_ENV
        end

        it 'is required when requiring any of the groups' do
          expect {
            envied_require(:foo)
          }.to raise_error(/bar/)

          expect {
            envied_require(:moo)
          }.to raise_error(/bar/)
        end
      end

      describe 'Hashable' do
        before do
          configure do
            variable :foo, :hash
            variable :bar, :hash
          end.and_ENV('foo' => 'a=1&b=&c', 'bar' => '')
          envied_require
        end

        it 'yields hash from string' do
          expect(ENVied.foo).to eq Hash['a'=> '1', 'b' => '', 'c' => nil]
        end

        it 'yields hash from an empty string' do
          expect(ENVied.bar).to eq Hash.new
        end

        context 'with defaults enabled' do
          before do
            configure(enable_defaults: true) do
              variable :baz, :hash
            end.and_no_ENV
          end

          it 'has no default by default' do
            # fixes a bug where variables of type :Hash had a default even
            # when none was configured.
            expect { envied_require }.to raise_error(RuntimeError, 'The following environment variables should be set: baz.')
          end
        end
      end

      describe 'Arrayable' do
        before do
          configure do
            variable :moar, :array
          end.and_ENV('moar' => 'a, b, and\, c')
          envied_require
        end

        it 'yields array from string' do
          expect(ENVied.moar).to eq ['a',' b',' and, c']
        end
      end

      describe 'URIable' do
        before do
          configure do
            variable :site_url, :uri
          end.and_ENV('site_url' => 'https://www.google.com')
          envied_require
        end

        it 'yields a URI from string' do
          expect(ENVied.site_url).to be_a URI
          expect(ENVied.site_url.host).to eq 'www.google.com'
        end
      end
    end
  end
end
