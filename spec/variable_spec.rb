require 'spec_helper'

describe ENVied::Variable do
  def variable(*args)
    described_class.new(*args)
  end

  def set_env(env)
    stub_const("ENV", env)
  end

  describe 'an instance' do
    subject { variable(:A, :String) }
    it { is_expected.to respond_to :missing? }
  end

  describe '#missing?' do
    subject { some_variable.missing? }
    let(:some_variable){ variable(:A, :String) }

    context "with ENV['A'] present" do
      before { set_env('A' => "1") }

      it { is_expected.to eq false }
    end

    context "with ENV['A'] not present" do
      before { set_env({}) }

      it { is_expected.to eq true }
    end
  end
end
