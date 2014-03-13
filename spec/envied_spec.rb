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

    def configured_with(hash = {})
      described_class.configure do |env|
        hash.each do |name, type|
          env.variable(name, *type)
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
      configured_with(a: :Integer).and_ENV({'A' => '1'})
      is_expected.to respond_to :a
    end

    it 'responds not to unconfigured variables' do
      unconfigured.and_ENV({'A' => '1'})
      is_expected.to_not respond_to :a
    end

    context 'ENV contains not all configured variables' do
      before { configured_with(a: :Integer).and_no_ENV }

      it 'raises EnvMissing on calling required!' do
        expect {
          ENVied.require!
        }.to raise_error(ENVied::Configurable::VariableMissingError)
      end

      it 'raises EnvMissing when interacted with' do
        expect {
          ENVied.any_missing_method
        }.to raise_error(ENVied::Configurable::VariableMissingError)
      end
    end

    context 'ENV containing variable of different type' do
      before { configured_with(a: :Integer).and_ENV('A' => 'NaN') }

      specify do
        expect {
          ENVied.a
        }.to raise_error(ENVied::Configurable::VariableTypeError)
      end
    end

    describe 'variable with default' do
      it 'can be a value' do
        configured_with(a: [:Integer, default: 1]).and_no_ENV
        expect(ENVied.a).to eq 1
      end

      it "can be anything callable" do
        configured_with(a: [:Integer, default: proc { 1 }]).and_no_ENV
        expect(ENVied.a).to eq 1
      end
    end
  end
end
