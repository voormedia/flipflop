require File.expand_path("../../../test_helper", __FILE__)

describe Flipflop::Strategies::SessionStrategy do
  subject do
    Flipflop::Strategies::SessionStrategy.new.freeze
  end

  describe "in request context" do
    before do
      Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = create_request
    end

    after do
      Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = nil
    end

    it "should have default name" do
      assert_equal "session", subject.name
    end

    it "should have title derived from name" do
      assert_equal "Session", subject.title
    end

    it "should have default description" do
      assert_equal "Stores features in the user session. Applies to current user.",
        subject.description
    end

    it "should be switchable" do
      assert_equal true, subject.switchable?(:test)
    end

    it "should have unique key" do
      assert_match /^\w+$/, subject.key
    end

    describe "with enabled feature" do
      before do
        subject.send(:request).session["one"] = true
      end

      it "should have feature enabled" do
        assert_equal true, subject.enabled?(:one)
      end

      it "should be able to switch feature off" do
        subject.switch!(:one, false)
        assert_equal false, subject.enabled?(:one)
      end

      it "should be able to clear feature" do
        subject.clear!(:one)
        assert_nil subject.enabled?(:one)
      end
    end

    describe "with disabled feature" do
      before do
        subject.send(:request).session["two"] = false
      end

      it "should not have feature enabled" do
        assert_equal false, subject.enabled?(:two)
      end

      it "should be able to switch feature on" do
        subject.switch!(:two, true)
        assert_equal true, subject.enabled?(:two)
      end

      it "should be able to clear feature" do
        subject.clear!(:two)
        assert_nil subject.enabled?(:two)
      end
    end

    describe "with unsessioned feature" do
      it "should not know feature" do
        assert_nil subject.enabled?(:three)
      end

      it "should be able to switch feature on" do
        subject.switch!(:three, true)
        assert_equal true, subject.enabled?(:three)
      end
    end

    describe "with options" do
      subject do
        Flipflop::Strategies::SessionStrategy.new(
          prefix: :my_feature_,
        ).freeze
      end

      before do
        subject.send(:request).session["my_feature_one"] = true
      end

      it "should use prefix to resolve parameters" do
        assert_equal true, subject.enabled?(:one)
      end
    end
  end

  describe "outside request context" do
    it "should not know feature" do
      assert_nil subject.enabled?(:one)
    end

    it "should not be switchable" do
      assert_equal false, subject.switchable?(:test)
    end

    it "should not be able to switch feature on" do
      assert_raises Flipflop::StrategyError do
        subject.switch!(:one, true)
      end
    end
  end
end
