# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

module SolidusPaysafe
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

    engine_name 'solidus_paysafe'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "spree.payment_method.add_solidus_paysafe_payment_method", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << "SolidusPaysafe::PaymentMethod"
    end
  end
end
