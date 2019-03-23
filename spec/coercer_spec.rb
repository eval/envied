RSpec.describe ENVied::Coercer do
  it { is_expected.to respond_to :coerce }
  it { is_expected.to respond_to :coerced? }
  it { is_expected.to respond_to :coercible? }
  it { is_expected.to respond_to :supported_types }
  it { is_expected.to respond_to :supported_type? }

  describe '.supported_types' do
    it 'returns a sorted set of supported types' do
      expect(described_class.supported_types).to eq %i(array boolean date float hash integer string symbol time uri)
    end
  end

  describe '.supported_type?' do
    it 'returns true for supported type' do
      %i(array boolean date float hash integer string symbol time uri).each do |type|
        expect(described_class.supported_type?(type)).to eq true
      end
    end

    it 'returns false for unsupported type' do
      expect(described_class.supported_type?(:fixnum)).to eq false
    end
  end

  describe '#supported_types' do
    it 'calls class method implementation' do
      expect(described_class).to receive(:supported_types).and_call_original
      described_class.new.supported_types
    end
  end

  describe '#supported_type?' do
    it 'calls class method implementation' do
      expect(described_class).to receive(:supported_type?).with(:string).and_call_original
      described_class.new.supported_type?(:string)
    end
  end

  describe '#coerced?' do
    let(:coercer) { described_class.new }

    it 'returns true if value has been coerced (not a string)' do
      expect(coercer.coerced?(1)).to eq true
    end

    it 'returns false if value is not a string' do
      expect(coercer.coerced?('1')).to eq false
    end
  end

  describe '#coercible?' do
    let(:coercer) { described_class.new }

    it 'returns false for unsupported type' do
      expect(coercer.coercible?('value', :invalid_type)).to eq false
    end

    it 'returns false for a failed coercion' do
      expect(coercer.coercible?('value', :boolean)).to eq false
    end

    it 'returns true for a coercible value' do
      expect(coercer.coercible?('value', :string)).to eq true
    end
  end

  describe '#coerce' do
    let(:coercer){ described_class.new }

    def coerce_to(type)
      ->(str){ coercer.coerce(str, type) }
    end

    describe 'to string' do
      let(:coerce){ coerce_to(:string) }

      it 'yields the input untouched' do
        expect(coerce['1']).to eq '1'
        expect(coerce[' 1']).to eq ' 1'
      end
    end

    describe 'to integer' do
      let(:coerce){ coerce_to(:integer) }

      it 'converts strings to integers' do
        expect(coerce['1']).to eq 1
        expect(coerce['-1']).to eq(-1)
      end

      it 'fails for float' do
        expect {
          coerce['1.23']
        }.to raise_error(Coercible::UnsupportedCoercion)
      end
    end

    describe 'to float' do
      let(:coerce){ coerce_to(:float) }

      it 'converts strings to floats' do
        expect(coerce['1.05']).to eq 1.05
        expect(coerce['-1.234']).to eq(-1.234)
      end
    end

    describe 'to boolean' do
      let(:coerce){ coerce_to(:boolean) }

      it "converts 'true' and 'false'" do
        expect(coerce['true']).to eq true
        expect(coerce['false']).to eq false
      end

      it "converts '1' and '0'" do
        expect(coerce['1']).to eq true
        expect(coerce['0']).to eq false
      end
    end

    describe 'to symbol' do
      let(:coerce){ coerce_to(:symbol) }

      it 'converts strings to symbols' do
        expect(coerce['a']).to eq :a
        expect(coerce['nice_symbol']).to eq :nice_symbol
      end
    end

    describe 'to date' do
      let(:coerce){ coerce_to(:date) }

      it 'converts strings to date' do
        expect(coerce['2014-12-25']).to eq Date.parse('2014-12-25')
      end
    end

    describe 'to time' do
      let(:coerce){ coerce_to(:time) }

      it 'converts strings to time' do
        expect(coerce['4:00']).to eq Time.parse('4:00')
      end
    end

    describe 'to array' do
      let(:coerce){ coerce_to(:array) }

      it 'converts strings to array' do
        {
          'a,b' => ['a','b'],
          ' a, b' => [' a',' b'],
          'apples,and\, of course\, pears' => ['apples','and, of course, pears'],
        }.each do |value, array|
          expect(coerce[value]).to eq array
        end
      end
    end

    describe 'to hash' do
      let(:coerce){ coerce_to(:hash) }

      it 'converts strings to hashes' do
        {
          'a=1' => {'a' => '1'},
          'a=1&b=2' => {'a' => '1', 'b' => '2'},
          'a=&b=2' => {'a' => '', 'b' => '2'},
          'a&b=2' => {'a' => nil, 'b' => '2'},
        }.each do |value, hash|
          expect(coerce[value]).to eq hash
        end
      end
    end

    describe 'to uri' do
      let(:coerce){ coerce_to(:uri) }

      it 'converts strings to uris' do
        expect(coerce['http://www.google.com']).to be_a(URI)
      end
    end
  end
end
