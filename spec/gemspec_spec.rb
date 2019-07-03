require "open3"

RSpec.describe 'building envied.gemspec' do

  def build!
    @build ||= Open3.capture3("gem build envied.gemspec")
    [:stdout, :stderr, :status].zip(@build).to_h
  end

  after do
    Dir.glob("envied-*.gem").each { |f| File.delete(f) }
  end

  it 'yields no warnings' do
    expect(build![:stderr]).to be_empty
  end

  specify do
    expect(build![:status]).to be_success
  end
end
