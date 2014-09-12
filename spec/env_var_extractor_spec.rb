require 'spec_helper'

describe ENVied::EnvVarExtractor do

  describe "#capture_variables" do
    def capture_variables(text)
      described_class.new.capture_variables(text)
    end

    {
      %{self.a = ENV['A']} => %w(A),
      %{self.a = ENV["A"]} => %w(A),
      %{self.a = ENV.fetch("A")]} => %w(A),
      %{self.a = ENV.fetch("A")]} => %w(A),
      %{# self.a = ENV["A"]} => %w(),
      %{self.a = ENV["A"] && self.b = ENV["B"]} => %w(A B)
    }.each do |line, expected|
      it "captures #{expected} from #{line.inspect}" do
        expect(capture_variables(line)).to contain_exactly(*expected)
      end
    end
  end
end
