require 'spec_helper'

describe ENVied::Configuration do
  it { is_expected.to respond_to :variable }
  it { is_expected.to respond_to :enable_defaults! }
  it { is_expected.to respond_to :defaults_enabled? }

  describe '#variable' do
    it 'results in an added variable' do

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
