require File.expand_path("../../../test_helper", __FILE__)

describe Flipflop::Strategies::DefaultStrategy do
  before do
    Flipflop::FeatureSet.current.replace do
      Flipflop.configure do
        feature :one, default: true
        feature :two
      end
    end
  end

  describe "with defaults" do
    subject do
      Flipflop::Strategies::DefaultStrategy.new.freeze
    end

    it "should have default name" do
      assert_equal "default", subject.name
    end

    it "should have title derived from name" do
      assert_equal "Default", subject.title
    end

    it "should have no default description" do
      assert_equal "Uses feature default status.", subject.description
    end

    it "should not be switchable" do
      assert_equal false, subject.switchable?(:test)
    end

    it "should have unique key" do
      assert_match /^\w+$/, subject.key
    end

    describe "with explicitly defaulted feature" do
      it "should have feature enabled" do
        assert_equal true, subject.enabled?(:one)
      end
    end

    describe "with implicitly defaulted feature" do
      it "should not have feature enabled" do
        assert_equal false, subject.enabled?(:two)
      end
    end
  end
end
