require 'spec_helper'

describe ENVied do
  subject { described_class }

  it { should respond_to :require }
  it { should respond_to :configure }

  context 'configured' do

    def unconfigured
      configured_with
      self
    end

    def configure(options = {}, &block)
      described_class.instance_eval { @configuration = nil }
      described_class.configure(options, &block)
      self
    end

    def configured_with(hash = {})
      described_class.instance_eval { @configuration = nil }
      described_class.configure do
        hash.each do |name, type|
          variable(name, *type)
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

    it 'responds to configured variables' do
      configured_with(a: :Integer).and_ENV({'a' => '1'})
      described_class.require

      is_expected.to respond_to :a
    end

    it 'responds not to unconfigured variables' do
      unconfigured.and_ENV({'A' => '1'})
      described_class.require

      is_expected.to_not respond_to :B
    end

    context 'ENV contains not all configured variables' do
      before { configured_with(a: :Integer).and_no_ENV }

      specify do
        expect {
          ENVied.require
        }.to raise_error /set the following ENV-variables: a/
      end
    end

    context 'ENV variables are not coercible' do
      before { configured_with(A: :Integer).and_ENV('A' => 'NaN') }

      specify do
        expect {
          ENVied.require
        }.to raise_error /ENV\['A'\] \('NaN' can't be coerced to Integer/
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
          }.to raise_error /bar/
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
            }.to raise_error /moar/
          end
        end
      end
    end
  end
end
