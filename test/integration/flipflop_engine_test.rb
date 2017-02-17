require File.expand_path("../../test_helper", __FILE__)

describe 'Flipflop::Engine' do
  before do
    TestApp.new
    @original_file = Flipflop::Engine.config_file
    Flipflop::Engine.config_file = 'test/foo'
  end

  after do
    Flipflop::Engine.config_file = @original_file
  end

  it "sets the config file" do
    assert_equal 'test/foo', Flipflop::Engine.config_file
  end
end
