require File.expand_path("../../../test_helper", __FILE__)

describe Flipflop::Strategies::QueryStringStrategy do
  subject do
    Flipflop::Strategies::QueryStringStrategy.new.freeze
  end

  describe "in request context" do
    before do
      Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = create_request
    end

    after do
      Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = nil
    end

    it "should have default name" do
      assert_equal "query_string", subject.name
    end

    it "should have title derived from name" do
      assert_equal "Query string", subject.title
    end

    it "should not have default description" do
      assert_equal "Interprets query string parameters as features.",
        subject.description
    end

    it "should not be switchable" do
      assert_equal false, subject.switchable?(:test)
    end

    it "should have unique key" do
      assert_match /^\w+$/, subject.key
    end

    describe "with enabled feature" do
      before do
        subject.send(:request).params[:one] = "1"
      end

      it "should have feature enabled" do
        assert_equal true, subject.enabled?(:one)
      end
    end

    describe "with disabled feature" do
      before do
        subject.send(:request).params[:two] = "0"
      end

      it "should not have feature enabled" do
        assert_equal false, subject.enabled?(:two)
      end
    end

    describe "with unknown feature" do
      it "should not know feature" do
        assert_nil subject.enabled?(:three)
      end
    end

    describe "with options" do
      subject do
        Flipflop::Strategies::QueryStringStrategy.new(
          prefix: :my_feature_,
        ).freeze
      end

      before do
        subject.send(:request).params[:my_feature_one] = "1"
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
  end
end
