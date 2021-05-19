# frozen_string_literal: true

require 'paysafe'

module SolidusPaysafe
  class Gateway
    attr_reader :client, :single_use_token, :test_mode

    AVS_CODE_CONVERTER = {
      'MATCH' => 'M',
      'MATCH_ADDRESS_ONLY' => 'A',
      'MATCH_ZIP_ONLY' => 'Z',
      'NO_MATCH' => 'N',
      'NOT_PROCESSED' => 'U',
      'UNKNOWN' => 'C'
    }.freeze

    CVV_CODE_CONVERTER = {
      'MATCH' => 'M',
      'NO_MATCH' => 'D',
      'NOT_PROCESSED' => 'P',
      'UNKNOWN' => 'X'
    }.freeze

    def initialize(options)
      @client = ::Paysafe::REST::Client.new(
        api_key: options[:api_key],
        api_secret: options[:api_secret],
        test_mode: options[:test_mode],
        account_number: options[:account_number]
      )
      @single_use_token = Base64.strict_encode64(
        "#{options[:single_use_token_key]}:#{options[:single_use_token_secret]}"
      )
      @test_mode = options[:test_mode]
    end

    def authorize(money, credit_card, options = {})
      create_authorization(money, credit_card, options.merge(settle_with_auth: false))
    end

    def capture(_money, authorization, options = {})
      payment = options[:originator]
      settlement = client.card_payments.create_settlement(
        auth_id: authorization,
        merchant_ref_num: options[:order_id]
      )
      payment.update(response_code: settlement.id)
      ActiveMerchant::Billing::Response.new(
        true,
        settlement.status,
        {},
        test: test_mode
      )
    rescue Paysafe::Error => e
      ActiveMerchant::Billing::Response.new(
        false,
        e.message,
        { message: e.message },
        test: test_mode
      )
    end

    def purchase(money, credit_card, options = {})
      create_authorization(money, credit_card, options.merge(settle_with_auth: true))
    end

    def credit(money, transaction_id, options = {})
      payment = options[:originator].payment

      settlement = client.card_payments.create_refund(
        settlement_id: transaction_id,
        merchant_ref_num: payment.order_id,
        amount: money
      )
      ActiveMerchant::Billing::Response.new(
        true,
        settlement.status,
        {},
        test: test_mode
      )
    rescue Paysafe::Error => e
      ActiveMerchant::Billing::Response.new(
        false,
        e.message,
        { message: e.message },
        test: test_mode
      )
    end

    def void(transaction_id, options = {})
      payment = options[:originator]

      if payment.completed?
        status = client.card_payments.cancel_settlement(
          settlement_id: transaction_id
        ).status
      else
        status = client.card_payments.void_authorization(
          auth_id: transaction_id,
          merchant_ref_num: payment.order_id,
          amount: payment.money.cents
        ).status
      end

      ActiveMerchant::Billing::Response.new(
        true,
        status,
        {},
        test: test_mode
      )
    rescue Paysafe::Error => e
      ActiveMerchant::Billing::Response.new(
        false,
        e.message,
        { message: e.message },
        test: test_mode
      )
    end

    def try_void(payment)
      if payment.completed?
        settlement = client.card_payments.get_settlement payment.response_code

        if settlement.status == 'COMPLETED'
          void(payment.response_code, options: { originator: payment })
        else
          false
        end
      else
        void(payment.response_code, options: { originator: payment })
      end
    end

    private

    def create_authorization(money, credit_card, options = {})
      authorization = client.card_payments.create_authorization build_authorization_data(money, credit_card, options)
      ActiveMerchant::Billing::Response.new(
        true,
        authorization.status,
        {},
        authorization: authorization.id,
        avs_result: { code: AVS_CODE_CONVERTER[authorization.avs_response] },
        cvv_result: CVV_CODE_CONVERTER[authorization.cvv_verification],
        test: test_mode
      )
    rescue Paysafe::Error => e
      ActiveMerchant::Billing::Response.new(
        false,
        e.message,
        { message: e.message },
        test: test_mode
      )
    end

    def build_authorization_data(money, credit_card, options)
      {
        merchant_ref_num: options[:order_id],
        amount: money,
        settle_with_auth: options[:settle_with_auth],
        card: { payment_token: credit_card.token },
        billing_details: {
          street: options[:billing_address][:address1],
          street2: options[:billing_address][:address2],
          city: options[:billing_address][:city],
          state: options[:billing_address][:state],
          country: options[:billing_address][:country],
          zip: options[:billing_address][:zip],
          phone: options[:billing_address][:phone]
        },
        shipping_details: {
          recipientName: options[:shipping_address][:name],
          street: options[:shipping_address][:address1],
          street2: options[:shipping_address][:address2],
          city: options[:shipping_address][:city],
          state: options[:shipping_address][:state],
          country: options[:shipping_address][:country],
          zip: options[:shipping_address][:zip]
        }
      }
    end
  end
end
