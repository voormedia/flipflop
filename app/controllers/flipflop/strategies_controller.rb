module Flipflop
  class StrategiesController < ApplicationController
    include ActionController::RequestForgeryProtection

    def update
      strategy.switch!(feature_key, enable?)
      redirect_to(features_url)
    end

    def destroy
      strategy.clear!(feature_key)
      redirect_to(features_url)
    end

    private

    def enable?
      if Rails::VERSION::MAJOR == 4
        if Rails::VERSION::MINOR == 1
          ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:commit])
        else
          ActiveRecord::Type::Boolean.new.type_cast_from_user(params[:commit])
        end
      else
        ActiveModel::Type::Boolean.new.cast(params[:commit])
      end
    end

    def feature_key
      params[:feature_id].to_sym
    end

    def strategy
      FeatureSet.current.strategy(params[:id])
    end
  end
end
