require File.expand_path("../../../test_helper", __FILE__)

require "fakeredis"

describe Flipflop::Strategies::RedisStrategy do
  before do
    Redis.new.flushall
  end

  describe "with defaults" do
    subject do
      Flipflop::Strategies::RedisStrategy.new.freeze
    end

    it "should have default name" do
      assert_equal "redis", subject.name
    end

    it "should have title derived from name" do
      assert_equal "Redis", subject.title
    end

    it "should have default description" do
      assert_equal "Stores features in Redis. Applies to all users.",
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
        Redis.new.set("one", 1)
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
        Redis.new.set("two", 0)
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

    describe "with unsaved feature" do
      it "should not know feature" do
        assert_nil subject.enabled?(:three)
      end

      it "should be able to switch feature on" do
        subject.switch!(:three, true)
        assert_equal true, subject.enabled?(:three)
      end
    end
  end

  describe "with options" do
    subject do
      Flipflop::Strategies::RedisStrategy.new(
        client: Redis.new(db: 1),
        prefix: "my_feature:",
      ).freeze
    end

    it "should use prefix and database to resolve parameters" do
      Redis.new(db: 1).set("my_feature:one", 1)
      assert_equal true, subject.enabled?(:one)
    end
  end
end
