require File.expand_path('../../../../test_helper', __FILE__)
require File.expand_path('../../../../../lib/tasks/support/methods', __FILE__)

describe Flipflop::Rake::SupportMethods do
  subject do
    object = Object.new
    object.extend Flipflop::Rake::SupportMethods
  end

  describe '#status_label' do
    it 'returns the "enabled" label when its argument is "true"' do
      assert_equal 'ON', subject.status_label(true)
    end

    it 'returns the "disabled" label when its argument is "false"' do
      assert_equal 'OFF', subject.status_label(false)
    end

    it 'returns the "unset" label when its argument is "nil"' do
      assert_equal '', subject.status_label(nil)
    end
  end

  def with_feature_and_strategy(strategy = 'Test')
    # Stubs finder methods to avoid going into FeatureSet code.
    feature = Flipflop::FeatureDefinition.new(:world_domination)
    subject.stub :find_feature_by_name, feature do
      classname = "#{strategy}Strategy"
      strategy = Flipflop::Strategies.const_get(classname).new(name: strategy)
      subject.stub :find_strategy_by_name, strategy do
        yield(strategy, feature) if block_given?
      end
    end
  end

  describe '#switch_feature!' do
    it 'enables a feature using a strategy' do
      with_feature_and_strategy do |strategy, feature|
        subject.switch_feature! 'world_domination', 'test', true
        assert_equal true, strategy.enabled?(feature.key)
      end
    end

    it 'disables a feature using a strategy' do
      with_feature_and_strategy do |strategy, feature|
        subject.switch_feature! 'world_domination', 'test', false
        assert_equal false, strategy.enabled?(feature.key)
      end
    end

    describe 'when the strategy is not switchable' do
      it 'raises an error' do
        with_feature_and_strategy 'Lambda' do |strategy, feature|
          -> { subject.switch_feature!('world_domination', 'lambda', true) }.must_raise
        end
      end
    end
  end

  describe '#clear_feature!' do
    it 'clears a feature using a strategy' do
      with_feature_and_strategy do |strategy, feature|
        subject.clear_feature! 'world_domination', 'test'
        assert_nil strategy.enabled?(feature.key)
      end
    end
  end
end
