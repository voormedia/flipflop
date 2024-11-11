require File.expand_path("../../../test_helper", __FILE__)

class ResultSet
  attr_reader :results

  def initialize(key, results = [])
    @key, @results = key, results
  end

  def first_or_initialize
    @results.first or MyAr::Feature.new(@key, false)
  end

  def first
    @results.first
  end
end

module MyAr
  class Feature < Struct.new(:key, :enabled)
    class << self
      attr_accessor :results

      def where(conditions)
        results[conditions[:key].to_sym]
      end

      def all
        results.values.flat_map(&:results)
      end
    end

    alias_method :enabled?, :enabled

    def destroy
      MyAr::Feature.results[key] = ResultSet.new(key)
    end

    def save!
      MyAr::Feature.results[key] = ResultSet.new(key, [self])
    end
  end
end

describe Flipflop::Strategies::ActiveRecordStrategy do
  describe "with defaults" do
    subject do
      Flipflop::Strategies::ActiveRecordStrategy.new(class: MyAr::Feature).freeze
    end

    it "should have default name" do
      assert_equal "active_record", subject.name
    end

    it "should have title derived from name" do
      assert_equal "Active record", subject.title
    end

    it "should have default description" do
      assert_equal "Stores features in database. Applies to all users.",
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
        MyAr::Feature.results = {
          one: ResultSet.new(:one, [MyAr::Feature.new(:one, true)]),
        }
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
        MyAr::Feature.results = {
          two: ResultSet.new(:two, [MyAr::Feature.new(:two, false)]),
        }
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
      before do
        MyAr::Feature.results = {
          three: ResultSet.new(:three),
        }
      end

      it "should not know feature" do
        assert_nil subject.enabled?(:three)
      end

      it "should be able to switch feature on" do
        subject.switch!(:three, true)
        assert_equal true, subject.enabled?(:three)
      end
    end
  end

  describe "with string class name" do
    subject do
      Flipflop::Strategies::ActiveRecordStrategy.new(class: "MyAr::Feature").freeze
    end

    before do
      MyAr::Feature.results = {
        one: ResultSet.new(:one, [MyAr::Feature.new(:one, true)]),
      }
    end

    it "should be able to switch feature off" do
      subject.switch!(:one, false)
      assert_equal false, subject.enabled?(:one)
    end
  end

  describe "with symbol class name" do
    subject do
      Flipflop::Strategies::ActiveRecordStrategy.new(class: :"MyAr::Feature").freeze
    end

    before do
      MyAr::Feature.results = {
        one: ResultSet.new(:one, [MyAr::Feature.new(:one, true)]),
      }
    end

    it "should be able to switch feature off" do
      subject.switch!(:one, false)
      assert_equal false, subject.enabled?(:one)
    end
  end

  describe "with eager loading" do
    before do
      Flipflop::FeatureCache.current.enable!
    end

    after do
      Flipflop::FeatureCache.current.disable!
    end

    subject do
      Flipflop::Strategies::ActiveRecordStrategy.new(class: MyAr::Feature, eager: true).freeze
    end

    it "should have default name" do
      assert_equal "active_record", subject.name
    end

    it "should have title derived from name" do
      assert_equal "Active record", subject.title
    end

    it "should have default description" do
      assert_equal "Stores features in database. Applies to all users.",
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
        MyAr::Feature.results = {
          one: ResultSet.new(:one, [MyAr::Feature.new(:one, true)]),
        }
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
        MyAr::Feature.results = {
          two: ResultSet.new(:two, [MyAr::Feature.new(:two, false)]),
        }
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
      before do
        MyAr::Feature.results = {
          three: ResultSet.new(:three),
        }
      end

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
