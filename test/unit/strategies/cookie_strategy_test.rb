require File.expand_path("../../../test_helper", __FILE__)

describe Flipflop::Strategies::CookieStrategy do
  subject do
    Flipflop::Strategies::CookieStrategy.new.freeze
  end

  describe "in request context" do
    before do
      Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = create_request
    end

    after do
      Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = nil
    end

    it "should have default name" do
      assert_equal "cookie", subject.name
    end

    it "should have title derived from name" do
      assert_equal "Cookie", subject.title
    end

    it "should have default description" do
      assert_equal "Stores features in a browser cookie. Applies to current user.",
        subject.description
    end

    it "should be switchable" do
      assert_equal true, subject.switchable?
    end

    it "should have unique key" do
      assert_match /^\w+$/, subject.key
    end

    describe "with enabled feature" do
      before do
        subject.send(:request).cookie_jar["one"] = "1"
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
        subject.send(:request).cookie_jar["two"] = "0"
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

    describe "with uncookied feature" do
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
        Flipflop::Strategies::CookieStrategy.new(
          domain: :all,
          path: "/foo",
          httponly: true,
          prefix: :my_cookie_,
        ).freeze
      end

      it "should use prefix to resolve parameters" do
        subject.send(:request).cookie_jar["my_cookie_one"] = "1"
        assert_equal true, subject.enabled?(:one)
      end

      it "should pass options when setting value" do
        subject.switch!(:one, true)
        subject.send(:request).cookie_jar.write(headers = {})
        assert_equal "my_cookie_one=1; domain=.example.com; path=/foo; HttpOnly",
          headers["Set-Cookie"]
      end

      it "should pass options when deleting value" do
        subject.switch!(:one, true)
        subject.clear!(:one)
        subject.send(:request).cookie_jar.write(headers = {})
        assert_equal "my_cookie_one=; domain=.example.com; path=/foo; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly",
          headers["Set-Cookie"]
      end
    end
  end

  describe "outside request context" do
    it "should not know feature" do
      assert_nil subject.enabled?(:one)
    end

    it "should not be switchable" do
      assert_equal false, subject.switchable?
    end

    it "should not be able to switch feature on" do
      assert_raises Flipflop::StrategyError do
        subject.switch!(:one, true)
      end
    end
  end
end
