require File.expand_path("../../../test_helper", __FILE__)

describe Flipflop::Strategies::AbstractStrategy do
  after do
    Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = nil
  end

  describe "with defaults" do
    subject do
      Flipflop::Strategies::AbstractStrategy.new.freeze
    end

    it "should have default name" do
      assert_equal "abstract", subject.name
    end

    it "should have title derived from name" do
      assert_equal "Abstract", subject.title
    end

    it "should have no default description" do
      assert_nil subject.description
    end

    it "should not be switchable" do
      assert_equal false, subject.switchable?(:test)
    end

    it "should not be hidden" do
      assert_equal false, subject.hidden?
    end

    it "should have unique key" do
      assert_match /^\w+$/, subject.key
    end

    describe "request" do
      it "should return request" do
        Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = 3
        assert_equal 3, subject.send(:request)
      end

      it "should raise error with message if request is missing" do
        Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = nil
        error = assert_raises Flipflop::StrategyError do
          subject.send(:request)
        end
        assert_equal "Strategy 'abstract' required request, but was used outside request context.", error.message
      end

      it "should raise if request is missing in thread" do
        Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = 3
        assert_raises Flipflop::StrategyError do
          Thread.new {
            if Thread.current.respond_to?(:report_on_exception)
              Thread.current.report_on_exception = false
            end

            subject.send(:request)
          }.value
        end
      end
    end

    describe "request predicate" do
      it "should return true if request is present" do
        Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = 3
        assert_equal true, subject.send(:request?)
      end

      it "should return false if request is missing" do
        Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = nil
        assert_equal false, subject.send(:request?)
      end
    end
  end

  describe "with options" do
    subject do
      Flipflop::Strategies::AbstractStrategy.new(
        name: "strategy",
        description: "my strategy",
        hidden: true,
      ).freeze
    end

    it "should have specified name" do
      assert_equal "strategy", subject.name
    end

    it "should have title derived from name" do
      assert_equal "Strategy", subject.title
    end

    it "should have specified description" do
      assert_equal "my strategy", subject.description
    end

    it "should be hidden" do
      assert_equal true, subject.hidden?
    end
  end

  describe "with unknown options" do
    subject do
      Flipflop::Strategies::AbstractStrategy.new(
        unknown: "one",
        other: "two",
      ).freeze
    end

    it "should raise error with message" do
      error = assert_raises Flipflop::StrategyError do
        subject
      end
      assert_equal "Strategy 'abstract' did not understand option :unknown, :other.", error.message
    end
  end
end
