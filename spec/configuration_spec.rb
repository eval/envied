require 'spec_helper'

describe ENVied::Configuration do
  it { is_expected.to respond_to :variable }
  it { is_expected.to respond_to :enable_defaults! }
  it { is_expected.to respond_to :defaults_enabled? }
  it { is_expected.to respond_to :type }

  describe '#variable' do
    subject { config.variables }

    context "with type" do
      let(:config) do
        described_class.new do
          variable :foo, :boolean
        end
      end

      it { is_expected.to include(ENVied::Variable.new(:foo, :boolean)) }
    end

    describe "with default" do
      let(:config) do
        described_class.new do
          variable :bar, default: 'bar'
        end
      end

      it { is_expected.to include(ENVied::Variable.new(:bar, :string, default: 'bar')) }
    end

    describe 'without type' do
      let(:config) do
        described_class.new do
          variable :bar
        end
      end

      it { is_expected.to include(ENVied::Variable.new(:bar, :string)) }
    end
  end

  describe '#type' do
    subject { config.coercer.custom_types }

    let(:coercer) { ->(raw_string) { Integer(raw_string) ** 2 } }
    let(:config) do
      block = coercer
      described_class.new do
        type(:power_integer, &block)
      end
    end

    it 'creates type with given coercing block' do
      is_expected.to include(power_integer: ENVied::Type.new(:power_integer, coercer))
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
