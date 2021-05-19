# frozen_string_literal: true

module SolidusPaysafe
  class PaymentMethod < ::Spree::PaymentMethod::CreditCard
    preference :api_key, :string
    preference :api_secret, :string
    preference :account_number, :string
    preference :single_use_token_key, :string
    preference :single_use_token_secret, :string

    delegate :try_void, to: :gateway

    def payment_source_class
      SolidusPaysafe::CreditCard
    end

    def partial_name
      'paysafe'
    end

    protected

    def gateway_class
      Gateway
    end
  end
end
