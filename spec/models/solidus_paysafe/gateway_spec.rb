# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusPaysafe::Gateway do
  subject(:gateway) do
    described_class.new(gateway_options)
  end

  let(:gateway_options) do
    {
      api_key: 'api_key',
      api_secret: 'API_SECRET',
      test_mode: true,
      account_number: '000',
      single_use_token_key: 'TOKEN_KEY',
      single_use_token_secret: 'TOKEN_SECRET'
    }
  end

  let(:paysafe_token) { 'TKLKJ71GOP9YSASU' }
  let(:authorization_id) { '1d4f8a01-cd8a-47c1-a361-ab124cd2b617' }
  let(:settlement_id) { 'ad4f8a01-cd8a-47c1-a361-ab124cd2b617' }
  let(:credit_card) { SolidusPaysafe::CreditCard.new encrypted_data: paysafe_token }
  let(:money) { 1000 }
  let(:payment) { ::Spree::Payment.new(state: 'completed', response_code: '123456') }
  let(:pending_payment) { ::Spree::Payment.new(state: 'pending', response_code: '654321') }
  let(:refund) { ::Spree::Refund.new(payment: payment) }
  let(:options) { {
    order_id: '123',
    settle_with_auth: false,
    billing_address: {
      address1: '123 Street',
      address2: 'Suite 666',
      city: 'Montreal',
      state: 'Quebec',
      country: 'Canada',
      zip: 'J1X 2X3',
      phone: '514-555-5555'
    },
    shipping_address: {
      recipientName: 'Jane Doe',
      address1: '321 Street',
      address2: 'Suite 123',
      city: 'Montreal',
      state: 'Quebec',
      country: 'Canada',
      zip: 'J9X 8X7',
    },
    originator: payment
  } }
  let(:purchase_options) { options.merge(settle_with_auth: true) }
  let(:options_with_refund_originator) { options.merge(originator: refund) }
  let(:options_with_pending_payment_originator) { options.merge(originator: pending_payment) }
  let(:card_payments) { Paysafe::Api::CardPaymentsApi.new gateway.client }
  let(:authorization) { Paysafe::Authorization.new(id: authorization_id, status: 'COMPLETED') }
  let(:settlement) { Paysafe::Settlement.new(id: settlement_id, status: 'COMPLETED') }
  let(:void_settlement) { Paysafe::Settlement.new(id: settlement_id, status: 'VOID') }

  describe 'initialize' do
    before { gateway }

    it 'sets the client' do
      expect(gateway.client).to be_a Paysafe::REST::Client
    end

    it 'sets api_key on the client' do
      expect(gateway.client.api_key).to eq('api_key')
    end

    it 'sets api_secret on the client' do
      expect(gateway.client.api_secret).to eq('API_SECRET')
    end

    it 'sets account_number on the client' do
      expect(gateway.client.account_number).to eq('000')
    end

    it 'sets single_use_token' do
      base64_token = Base64.strict_encode64('TOKEN_KEY:TOKEN_SECRET')
      expect(gateway.single_use_token).to eq(base64_token)
    end

    it 'sets test_mode' do
      expect(gateway.test_mode).to be_truthy
    end

    describe 'when test_mode is false' do
      before do
        @gateway = described_class.new(gateway_options.merge(test_mode: false))
      end

      it 'sets test_mode' do
        expect(@gateway.test_mode).to be_falsey
      end
    end
  end

  describe '#authorize' do
    before do
      allow(gateway.client).to receive(:card_payments) { card_payments }
    end

    context 'with valid data' do
      before do
        allow(card_payments).to receive(:create_authorization) { authorization }
      end

      it 'builds the proper authorization data' do
        expect(card_payments).to receive(:create_authorization).with(
          gateway.send :build_authorization_data, money, credit_card, options
        )
        gateway.authorize(money, credit_card, options)
      end

      it 'returns a successful ActiveMerchant::Response' do
        response = gateway.authorize(money, credit_card, options)
        expect(response).to be_success
      end

      it 'returns the authorization_id in the ActiveMerchant response' do
        response = gateway.authorize(money, credit_card, options)
        expect(response.authorization).to eq(authorization_id)
      end

      it 'returns the status message in the ActiveMerchant response' do
        response = gateway.authorize(money, credit_card, options)
        expect(response.message).to eq('COMPLETED')
      end
    end

    context 'with invalid data' do
      before do
        allow(card_payments).to receive(:create_authorization).and_raise(Paysafe::Error, message: 'Error!')
      end

      it 'returns an unsuccessful ActiveMerchant::Response' do
        response = gateway.authorize(money, credit_card, options)
        expect(response).not_to be_success
      end

      it 'returns the error message in the response' do
        response = gateway.authorize(money, credit_card, options)
        expect(response.message).to eq('Error!')
      end
    end
  end

  describe '#purchase' do
    before do
      allow(gateway.client).to receive(:card_payments) { card_payments }
      allow(card_payments).to receive(:create_authorization) { authorization }
    end

    it 'builds the proper authorization data' do
      expect(card_payments).to receive(:create_authorization).with(
        gateway.send :build_authorization_data, money, credit_card, purchase_options
      )
      gateway.purchase(money, credit_card, options)
    end
  end

  describe '#capture' do
    before do
      allow(gateway.client).to receive(:card_payments) { card_payments }
    end

    context 'with valid data' do
      before do
        allow(card_payments).to receive(:create_settlement) { settlement }
        allow(payment).to receive(:update)
      end

      it 'returns a successful ActiveMerchant::Response' do
        response = gateway.capture(money, paysafe_token, options)
        expect(response).to be_success
      end

      it 'updates the response_code to the settlement_id' do
        expect(payment).to receive(:update).with(response_code: settlement.id)
        gateway.capture(money, paysafe_token, options)
      end
    end

    context 'with invalid data' do
      before do
        allow(card_payments).to receive(:create_settlement).and_raise(Paysafe::Error, message: 'Error!')
      end

      it 'returns an unsuccessful ActiveMerchant::Response' do
        response = gateway.capture(money, paysafe_token, options)
        expect(response).not_to be_success
      end

      it 'returns the error message in the response' do
        response = gateway.capture(money, paysafe_token, options)
        expect(response.message).to eq('Error!')
      end
    end
  end

  describe '#credit' do
    before do
      allow(gateway.client).to receive(:card_payments) { card_payments }
    end

    context 'with valid data' do
      before do
        allow(card_payments).to receive(:create_refund) { settlement }
      end

      it 'returns a successful ActiveMerchant::Response' do
        response = gateway.credit(money, settlement_id, options_with_refund_originator)
        expect(response).to be_success
      end
    end

    context 'with invalid data' do
      before do
        allow(card_payments).to receive(:create_refund).and_raise(Paysafe::Error, message: 'Error!')
      end

      it 'returns an unsuccessful ActiveMerchant::Response' do
        response = gateway.credit(money, settlement_id, options_with_refund_originator)
        expect(response).not_to be_success
      end

      it 'returns the error message in the response' do
        response = gateway.credit(money, settlement_id, options_with_refund_originator)
        expect(response.message).to eq('Error!')
      end
    end
  end

  describe '#void' do
    before do
      allow(gateway.client).to receive(:card_payments) { card_payments }
    end

    context 'when a payment was completed' do
      context 'with valid data' do
        before do
          allow(card_payments).to receive(:cancel_settlement) { settlement }
        end

        it 'returns a successful ActiveMerchant::Response' do
          response = gateway.void(settlement_id, options)
          expect(response).to be_success
        end
      end

      context 'with invalid data' do
        before do
          allow(card_payments).to receive(:cancel_settlement).and_raise(Paysafe::Error, message: 'Error!')
        end

        it 'returns an unsuccessful ActiveMerchant::Response' do
          response = gateway.void(settlement_id, options)
          expect(response).not_to be_success
        end

        it 'returns the error message in the response' do
          response = gateway.void(settlement_id, options)
          expect(response.message).to eq('Error!')
        end
      end
    end

    context 'when a payment was not completed' do
      before do
        allow(pending_payment).to receive(:money) { ::Spree::Money.new(10) }
      end

      context 'with valid data' do
        before do
          allow(card_payments).to receive(:void_authorization) { settlement }
        end

        it 'returns a successful ActiveMerchant::Response' do
          response = gateway.void(settlement_id, options_with_pending_payment_originator)
          expect(response).to be_success
        end
      end

      context 'with invalid data' do
        before do
          allow(card_payments).to receive(:void_authorization).and_raise(Paysafe::Error, message: 'Error!')
        end

        it 'returns an unsuccessful ActiveMerchant::Response' do
          response = gateway.void(settlement_id, options_with_pending_payment_originator)
          expect(response).not_to be_success
        end

        it 'returns the error message in the response' do
          response = gateway.void(settlement_id, options_with_pending_payment_originator)
          expect(response.message).to eq('Error!')
        end
      end
    end
  end

  describe '#try_void' do
    before do
      allow(gateway.client).to receive(:card_payments) { card_payments }
    end

    context 'with a completed payment' do
      context 'and a completed settlement' do
        before do
          allow(card_payments).to receive(:get_settlement) { settlement }
        end

        it 'calls void' do
          expect(gateway).to receive(:void).with('123456', options: { originator: payment })
          gateway.try_void(payment)
        end
      end

      context 'and a void settlement' do
        before do
          allow(card_payments).to receive(:get_settlement) { void_settlement }
        end

        it 'returns false' do
          response = gateway.try_void(payment)
          expect(response).to be_falsey
        end
      end
    end

    context 'with a pending payment' do
      it 'calls void' do
        expect(gateway).to receive(:void).with('654321', options: { originator: pending_payment })
        gateway.try_void(pending_payment)
      end
    end
  end
end
