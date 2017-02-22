require 'spec_helper'

describe ENVied::Coercer do
  it { is_expected.to respond_to :coerce }

  describe '#coerce' do
    let(:coercer){ described_class.new }

    def coerce_to(type)
      ->(str){ coercer.coerce(str, type) }
    end

    describe 'string coercion' do
      let(:coerce){ coerce_to(:String) }

      it 'yields the input untouched' do
        expect(coerce['1']).to eq '1'
        expect(coerce[' 1']).to eq ' 1'
      end
    end

    describe 'integer coercion' do
      let(:coerce){ coerce_to(:Integer) }

      it 'converts strings to integers' do
        expect(coerce['1']).to eq 1
        expect(coerce['-1']).to eq(-1)
      end
    end

    describe 'float coercion' do
      let(:coerce){ coerce_to(:Float) }

      it 'converts strings to floats' do
        expect(coerce['1.05']).to eq 1.05
        expect(coerce['-1.234']).to eq(-1.234)
      end
    end

    describe 'boolean coercion' do
      let(:coerce){ coerce_to(:Boolean) }

      it "converts 'true' and 'false'" do
        expect(coerce['true']).to eq true
        expect(coerce['false']).to eq false
      end

      it "converts '1' and '0'" do
        expect(coerce['1']).to eq true
        expect(coerce['0']).to eq false
      end
    end

    describe 'symbol coercion' do
      let(:coerce){ coerce_to(:Symbol) }

      it 'converts strings to symbols' do
        expect(coerce['a']).to eq :a
        expect(coerce['nice_symbol']).to eq :nice_symbol
      end
    end

    describe 'date coercion' do
      let(:coerce){ coerce_to(:Date) }

      it 'converts strings to date' do
        expect(coerce['2014-12-25']).to eq Date.parse('2014-12-25')
      end
    end

    describe 'time coercion' do
      let(:coerce){ coerce_to(:Time) }

      it 'converts strings to time' do
        expect(coerce['4:00']).to eq Time.parse('4:00')
      end
    end

    describe 'array coercion' do
      let(:coerce){ coerce_to(:Array) }

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

    describe 'hash coercion' do
      let(:coerce){ coerce_to(:Hash) }

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

    describe 'uri coercion' do
      let(:coerce){ coerce_to(:Uri) }

      it 'converts strings to uris' do
        expect(coerce['http://www.google.com']).to be_a(URI)
      end
    end
  end
end
