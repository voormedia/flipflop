require File.expand_path("../../test_helper", __FILE__)

describe 'Flipflop::StrategiesController' do
  before do
    @app = TestApp.new
  end

  after do
    @app.unload!
  end
  
  subject do
    Flipflop::StrategiesController.new.tap { |c| c.params = @params }
  end

  describe "#enable?" do
    it 'is true when commit is "1"' do
      @params = ActionController::Parameters.new(commit: '1')
      assert_same subject.send(:enable?), true
    end

    it 'is nil when commit is empty string' do
      @params = ActionController::Parameters.new(commit: '')
      assert_nil subject.send(:enable?)
    end

    if ENV['RAILS_VERSION'] == '4.1'
      it 'is false when commit is nil' do
        @params = ActionController::Parameters.new
        assert_same subject.send(:enable?), false
      end
    else
      it 'is nil when commit is nil' do
        @params = ActionController::Parameters.new
        assert_nil subject.send(:enable?)
      end
    end


    it 'is true when commit is "on"' do
      @params = ActionController::Parameters.new(commit: 'on')
      assert_same subject.send(:enable?), true
    end


  end
end
