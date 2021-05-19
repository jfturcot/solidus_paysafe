# frozen_string_literal: true

require 'paysafe'

module Paysafe
  module Api
    module CardPaymentsApiDecorator
      def void_authorization(auth_id:, merchant_ref_num:, amount:, **data)
        perform_post_with_object(
          "/cardpayments/v1/accounts/#{account_number}/auths/#{auth_id}/voidauths",
          data.merge(merchant_ref_num: merchant_ref_num, amount: amount),
          Settlement
        )
      end

      def create_settlement(auth_id:, **data)
        perform_post_with_object(
          "/cardpayments/v1/accounts/#{account_number}/auths/#{auth_id}/settlements", data, Settlement
        )
      end

      def get_settlement(settlement_id)
        perform_get_with_object("/cardpayments/v1/accounts/#{account_number}/settlements/#{settlement_id}", Settlement)
      end

      def cancel_settlement(settlement_id:, **data)
        perform_put_with_object(
          "/cardpayments/v1/accounts/#{account_number}/settlements/#{settlement_id}",
          data.merge(status: 'CANCELLED'),
          Settlement
        )
      end

      def create_refund(settlement_id:, merchant_ref_num:, **data)
        perform_post_with_object(
          "/cardpayments/v1/accounts/#{account_number}/settlements/#{settlement_id}/refunds",
          data.merge(merchant_ref_num: merchant_ref_num),
          Settlement
        )
      end

      ::Paysafe::Api::CardPaymentsApi.prepend self
    end
  end
end
