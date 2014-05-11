require 'spec_helper'

describe ENVied do
  subject { described_class }

  it { should respond_to :require! }
  it { should respond_to :configure }

  context 'configured' do

    def unconfigured
      configured_with
      self
    end

    def configure(options = {}, &block)
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
      described_class.require!

      is_expected.to respond_to :a
    end

    it 'responds not to unconfigured variables' do
      unconfigured.and_ENV({'A' => '1'})
      described_class.require!

      is_expected.to_not respond_to :B
    end

    context 'ENV contains not all configured variables' do
      before { configured_with(a: :Integer).and_no_ENV }

      specify do
        expect {
          ENVied.require!
        }.to raise_error /set the following ENV-variables: a/
      end
    end

    context 'ENV variables are not coercible' do
      before { configured_with(A: :Integer).and_ENV('A' => 'NaN') }

      specify do
        expect {
          ENVied.require!
        }.to raise_error /ENV\['A'\] can't be coerced to Integer/
      end
    end
  end
end
