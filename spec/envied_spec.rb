require 'spec_helper'

describe ENVied do
  describe 'class' do
    subject { described_class }

    it { is_expected.to respond_to :require }
  end

  describe 'responding to methods that are variables' do
  end

  before do
    reset_env
    reset_configuration
  end

  def reset_configuration
    ENVied.instance_eval { @config = nil }
  end

  def reset_env
    ENVied.instance_eval { @env = nil }
  end

  context 'configured' do

    def unconfigured
      configured_with
      self
    end

    def configure(options = {}, &block)
      ENVied.instance_eval do
        @config = ENVied::Configuration.new.tap{|c| c.instance_eval(&block)}
      end
      self
    end

    def configured_with(hash = {})
      config = ENVied::Configuration.new.tap do |c|
        hash.each do |name, type|
          c.variable(name, *type)
        end
      end
      ENVied.instance_eval{ @config = config }
      self
    end

    def and_ENV(env = {})
      stub_const("ENV", env)
      described_class
    end

    def and_no_ENV
      and_ENV
    end

    it 'responds to configured variables' do
      configured_with(a: :Integer).and_ENV({'a' => '1'})
      described_class.require

      expect(described_class).to respond_to :a
    end

    it 'responds not to unconfigured variables' do
      unconfigured.and_ENV({'A' => '1'})
      described_class.require

      expect(described_class).to_not respond_to :B
    end

    context 'ENV contains not all configured variables' do
      before { configured_with(a: :Integer).and_no_ENV }

      specify do
        expect {
          ENVied.require
        #}.to raise_error(/The following environment variables should be set: a/)
        }.to raise_error(/Missing: a/)
      end
    end

    context 'ENV variables are not coercible' do
      before { configured_with(A: :Integer).and_ENV('A' => 'NaN') }

      specify do
        expect {
          ENVied.require
        #}.to raise_error(/A \('NaN' can't be coerced to Integer/)
        }.to raise_error(/Uncoercible: A/)
      end
    end

    context 'bug: default value "false" is not coercible' do
      before {
        configure(enable_defaults: true) do
          variable :FORCE_SSL, :Boolean, default: false
        end
      }

      specify do
        expect {
          ENVied.require
        }.not_to raise_error
      end
    end

    describe 'defaults' do
      describe 'setting' do
        subject { described_class.configuration }

        it 'is disabled by default' do
          expect(subject.enable_defaults).to_not be
        end

        it 'can be enabled via #configure' do
          configure(enable_defaults: true){ }

          expect(subject.enable_defaults).to be
        end

        it 'can be enabled via a configure-block' do
          configure { self.enable_defaults = true }

          expect(subject.enable_defaults).to be
        end

        it 'can be assigned a Proc' do
          configure { self.enable_defaults = -> { true } }

          expect(subject.enable_defaults).to be
        end
      end

      describe 'assigning' do
        it 'can be a value' do
          configure(enable_defaults: true) do
            variable :A, :Integer, default: 1
          end
          described_class.require

          expect(described_class.A).to eq 1
        end

        it 'can be a Proc' do
          configure(enable_defaults: true) do
            variable :A, :Integer, default: proc { 1 }
          end
          described_class.require

          expect(described_class.A).to eq 1
        end

        it 'is ignored if defaults are disabled' do
          configure(enable_defaults: false) do
            variable :A, :Integer, default: 1
          end.and_no_ENV

          expect {
            described_class.require
          }.to raise_error
        end

        it 'is is ignored if ENV is provided' do
          configure(enable_defaults: true) do
            variable :A, :Integer, default: 1
          end.and_ENV('A' => '2')
          described_class.require

          expect(described_class.A).to eq 2
        end

        it 'can be defined in terms of other variables' do
          configure(enable_defaults: true) do
            variable :A, :Integer
            variable :B, :Integer, default: proc {|env| env.A * 2 }
          end.and_ENV('A' => '1')
          described_class.require

          expect(described_class.B).to eq 2
        end
      end
    end

    describe "groups" do
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
            described_class.require(:foo)
          }.to raise_error(/bar/)
        end

        it 'is not required when requiring another group' do
          expect {
            described_class.require(:bat)
          }.to_not raise_error
        end

        it 'wont define non-required variables on ENVied' do
          stub_const("ENV", {'moar' => 'yes'})
          described_class.require(:default)

          expect {
            described_class.bar
          }.to raise_error
        end

        it 'requires variables without a group when requiring the default group' do
          [:default, 'default'].each do |groups|
            expect {
              described_class.require(*groups)
            }.to raise_error(/moar/)
          end
        end
      end

      describe 'Hashable' do
        before do
          configure do
            variable :foo, :Hash
            variable :bar, :Hash
          end.and_ENV('foo' => 'a=1&b=&c', 'bar' => '')
          ENVied.require
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
              variable :baz, :Hash
            end.and_no_ENV
          end

          it 'has no default by default' do
            # fixes a bug where variables of type :Hash had a default even
            # when none was configured.
            expect { ENVied.require(:default) }.to raise_error
          end
        end
      end

      describe 'Arrayable' do
        before do
          configure do
            variable :moar, :Array
          end.and_ENV('moar' => 'a, b, and\, c')
          ENVied.require
        end

        it 'yields array from string' do
          expect(ENVied.moar).to eq ['a',' b',' and, c']
        end
      end
    end
  end
end
