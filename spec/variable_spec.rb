require 'spec_helper'

describe ENVied::Variable do
  def variable(*args)
    described_class.new(*args)
  end

  describe 'an instance' do
    subject { variable(:A, :string) }
    it { is_expected.to respond_to :name }
    it { is_expected.to respond_to :type }
    it { is_expected.to respond_to :group }
    it { is_expected.to respond_to :default }
    it { is_expected.to respond_to :== }
    it { is_expected.to respond_to :default_value }
  end

  describe 'defaults' do
    it 'returns the default value as it is' do
      expect(variable(:A, :string, default: 'A').default_value).to eq 'A'
    end

    it 'returns the default value from calling the proc provided' do
      expect(variable(:A, :string, default: ->{ 'A' * 2 }).default_value).to eq 'AA'
    end
  end
end
