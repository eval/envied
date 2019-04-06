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

    def coerce(str, type)
      coercer.coerce(str, type)
    end

    it 'fails with an invalid type' do
      expect { coerce('', :fixnum) }.to raise_error(ArgumentError, "The type `:fixnum` is not supported.")
    end

    describe 'to string' do
      it 'returns the input untouched' do
        expect(coerce('1', :string)).to eq '1'
        expect(coerce(' 1', :string)).to eq ' 1'
      end

      it 'fails when the value does not respond to #to_str' do
        value = Object.new
        expect { coerce(value, :string) }.to raise_error(ENVied::Coercer::UnsupportedCoercion)
      end
    end

    describe 'to integer' do
      {
        '1' => 1,
        '+1' => 1,
        '-1' => -1,
        '10' => 10,
        '100_00' => 100_00,
        '1_000_00' => 1_000_00
      }.each do |value, integer|
        it "converts #{value.inspect} to an integer" do
          expect(coerce(value, :integer)).to be_kind_of(Integer)
          expect(coerce(value, :integer)).to eq integer
        end
      end

      it 'fails with an invalid string' do
        expect { coerce('non-integer', :integer) }.to raise_error(ENVied::Coercer::UnsupportedCoercion)
      end

      it 'fails with a float' do
        expect { coerce('1.23', :integer) }.to raise_error(ENVied::Coercer::UnsupportedCoercion)
      end
    end

    describe 'to float' do
      {
        '1' => 1.0,
        '+1' => 1.0,
        '-1' => -1.0,
        '1_000.0' => 1_000.0,
        '10_000.23' => 10_000.23,
        '1_000_000.0' => 1_000_000.0,
        '1.0' => 1.0,
        '1.234' => 1.234,
        '1.0e+1' => 10.0,
        '1.0e-1' => 0.1,
        '1.0E+1' => 10.0,
        '1.0E-1' => 0.1,
        '+1.0' => 1.0,
        '+1.0e+1' => 10.0,
        '+1.0e-1' => 0.1,
        '+1.0E+1' => 10.0,
        '+1.0E-1' => 0.1,
        '-1.0' => -1.0,
        '-1.234' => -1.234,
        '-1.0e+1' => -10.0,
        '-1.0e-1' => -0.1,
        '-1.0E+1' => -10.0,
        '-1.0E-1' => -0.1,
        '.1' => 0.1,
        '.1e+1' => 1.0,
        '.1e-1' => 0.01,
        '.1E+1' => 1.0,
        '.1E-1' => 0.01,
        '1e1' => 10.0,
        '1E+1' => 10.0,
        '+1e-1' => 0.1,
        '-1E1' => -10.0,
        '-1e-1' => -0.1,
      }.each do |value, float|
        it "converts #{value.inspect} to a float" do
          expect(coerce(value, :float)).to be_kind_of(Float)
          expect(coerce(value, :float)).to eq float
        end
      end

      it 'fails with an invalid string' do
        expect { coerce('non-float', :float) }.to raise_error(ENVied::Coercer::UnsupportedCoercion)
      end

      it 'fails when string starts with e' do
        expect { coerce('e1', :float) }.to raise_error(ENVied::Coercer::UnsupportedCoercion)
      end
    end

    describe 'to boolean' do
      %w[ 1 on ON t true T TRUE y yes Y YES ].each do |value|
        it "converts #{value.inspect} to `true`" do
          expect(coerce(value, :boolean)).to eq true
        end
      end

      %w[ 0 off OFF f false F FALSE n no N NO ].each do |value|
        it "converts #{value.inspect} to `false`" do
          expect(coerce(value, :boolean)).to eq false
        end
      end

      it 'fails with an invalid boolean string' do
        expect { coerce('non-boolean', :boolean) }.to raise_error(ENVied::Coercer::UnsupportedCoercion)
      end
    end

    describe 'to symbol' do
      it 'converts strings to symbols' do
        expect(coerce('a', :symbol)).to eq :a
        expect(coerce('nice_symbol', :symbol)).to eq :nice_symbol
      end
    end

    describe 'to date' do
      it 'converts string to date' do
        date = coerce('2019-03-22', :date)

        expect(date).to be_instance_of(Date)
        expect(date.year).to eq 2019
        expect(date.month).to eq 3
        expect(date.day).to eq 22
      end

      it 'converts other string formats to date' do
        expect(coerce('March 22nd, 2019', :date)).to eq Date.parse('2019-03-22')
        expect(coerce('Sat, March 23rd, 2019', :date)).to eq Date.parse('2019-03-23')
      end

      it 'fails with an invalid string' do
        expect { coerce('non-date', :date) }.to raise_error(ENVied::Coercer::UnsupportedCoercion)
      end
    end

    describe 'to time' do
      it 'converts string to time without time part' do
        time = coerce("2019-03-22", :time)

        expect(time).to be_instance_of(Time)
        expect(time.year).to eq 2019
        expect(time.month).to eq 3
        expect(time.day).to eq 22
        expect(time.hour).to eq 0
        expect(time.min).to eq 0
        expect(time.sec).to eq 0
      end

      it 'converts string to time with time portion' do
        time = coerce("March 22nd, 2019 9:30:55", :time)

        expect(time).to be_instance_of(Time)
        expect(time.year).to eq 2019
        expect(time.month).to eq 3
        expect(time.day).to eq 22
        expect(time.hour).to eq 9
        expect(time.min).to eq 30
        expect(time.sec).to eq 55
      end

      it 'fails with an invalid string' do
        expect { coerce('2999', :time) }.to raise_error(ENVied::Coercer::UnsupportedCoercion)
      end
    end

    describe 'to array' do
      it 'converts strings to array' do
        {
          'a,b' => ['a','b'],
          ' a, b' => [' a',' b'],
          'apples,and\, of course\, pears' => ['apples','and, of course, pears'],
        }.each do |value, array|
          expect(coerce(value, :array)).to eq array
        end
      end
    end

    describe 'to hash' do
      it 'converts strings to hashes' do
        {
          'a=1' => {'a' => '1'},
          'a=1&b=2' => {'a' => '1', 'b' => '2'},
          'a=&b=2' => {'a' => '', 'b' => '2'},
          'a&b=2' => {'a' => nil, 'b' => '2'},
        }.each do |value, hash|
          expect(coerce(value, :hash)).to eq hash
        end
      end
    end

    describe 'to uri' do
      it 'converts strings to uris' do
        expect(coerce('https://www.google.com', :uri)).to be_a(URI)
        expect(coerce('https://www.google.com', :uri).scheme).to eq 'https'
        expect(coerce('https://www.google.com', :uri).host).to eq 'www.google.com'
      end
    end
  end
end
