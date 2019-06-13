RSpec.describe ENVied::Variable do
  def variable(*args)
    described_class.new(*args)
  end

  describe 'an instance' do
    subject { variable(:A, :string) }
    it { is_expected.to respond_to :name }
    it { is_expected.to respond_to :type }
    it { is_expected.to respond_to :group }
    it { is_expected.to respond_to :== }
  end
end
