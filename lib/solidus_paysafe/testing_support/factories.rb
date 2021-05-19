# frozen_string_literal: true

FactoryBot.define do
  factory :paysafe_payment_method, class: 'SolidusPaysafe::PaymentMethod' do
    name { "Paysafe" }
    preferred_api_key { "test_test" }
    preferred_api_secret { "api000" }
    preferred_account_number { "000000" }
    preferred_single_use_token_key { "test2_test2" }
    preferred_single_use_token_secret { "api111" }
  end

  factory :paysafe_credit_card, class: 'SolidusPaysafe::CreditCard' do
    name { "John Doe" }
    encrypted_data { "XXXXXXXXXXXXXXXX" }
  end
end
