require File.expand_path("../../../test_helper", __FILE__)

describe Flipflop::Strategies::TestStrategy do
  describe "with defaults" do
    subject do
      Flipflop::Strategies::TestStrategy.new.freeze
    end

    it "should have default name" do
      assert_equal "test", subject.name
    end

    it "should have title derived from name" do
      assert_equal "Test", subject.title
    end

    it "should not have default description" do
      assert_nil subject.description
    end

    it "should be switchable" do
      assert_equal true, subject.switchable?(:test)
    end

    it "should have unique key" do
      assert_match /^\w+$/, subject.key
    end

    describe "with enabled feature" do
      before do
        subject.switch!(:one, true)
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
        subject.switch!(:two, false)
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
end
