require "open3"

RSpec.describe 'envied.gemspec' do
  let!(:build) { Open3.capture3("gem build envied.gemspec") }

  after do
    Dir.glob("envied-*.gem").each { |f| File.delete(f) }
  end

  it 'builds without warnings' do
    expect(build[1]).to_not match(/WARNING/)
  end

  it 'builds successfully' do
    expect(build[2].success?).to eq true
  end
end
