require 'spec_helper'

describe ENVied::Coercer do
  it { is_expected.to respond_to :coerce }

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
        }.each do |i, o|
          expect(coerce[i]).to eq o
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
        }.each do |i, o|
          expect(coerce[i]).to eq o
        end
      end
    end

    describe 'to uri' do
      let(:coerce){ coerce_to(:uri) }

      it 'converts strings to generic uris' do
        expect(coerce['server.example.com']).to be_a(URI::Generic)
      end

      it 'converts strings to ftp uris' do
        expect(coerce['ftp://ftp.example.com']).to be_a(URI::FTP)
      end
    end

    describe 'to uri_with_scheme' do
      let(:coerce){ coerce_to(:uri_with_scheme) }

      it 'converts strings to http uris' do
        expect(coerce['http://www.google.com'].scheme).to eql 'http'
      end

      it 'converts strings to https uris' do
        expect(coerce['https://github.com'].scheme).to eql 'https'
      end

      it 'converts strings to redis uris' do
        expect(coerce['redis://example.com:6379'].scheme).to eql 'redis'
      end

      it 'fails for non uris' do
        expect {
          coerce['server.example.com']
        }.to raise_error(Coercible::UnsupportedCoercion)
      end
    end
  end
end
