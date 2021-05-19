# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Paysafe::Api::CardPaymentsApi do
  let(:client) {
    Paysafe::REST::Client.new(
      account_number: '000',
      api_key: 'api_key',
      api_secret: 'API_SECRET'
    )
  }

  subject do
    described_class.new(client)
  end

  describe '#void_authorization' do
    it 'performs a post on settlements' do
      expect(subject).to receive(:perform_post_with_object).with(
        '/cardpayments/v1/accounts/000/auths/6d4f8a01-cd8a-47c1-a361-ab124cd2b617/voidauths',
        { merchant_ref_num: 'abc123', amount: 1000, test: '' },
        Paysafe::Settlement
      )
      subject.void_authorization(
        auth_id: '6d4f8a01-cd8a-47c1-a361-ab124cd2b617',
        merchant_ref_num: 'abc123',
        amount: 1000,
        test: ''
      )
    end
  end

  describe '#create_settlement' do
    it 'performs a post on settlements' do
      expect(subject).to receive(:perform_post_with_object).with(
        '/cardpayments/v1/accounts/000/auths/6d4f8a01-cd8a-47c1-a361-ab124cd2b617/settlements',
        { test: '' },
        Paysafe::Settlement
      )
      subject.create_settlement(auth_id: '6d4f8a01-cd8a-47c1-a361-ab124cd2b617', test: '')
    end
  end

  describe '#get_settlement' do
    it 'performs a get on settlements' do
      expect(subject).to receive(:perform_get_with_object).with(
        '/cardpayments/v1/accounts/000/settlements/6d4f8a01-cd8a-47c1-a361-ab124cd2b617',
        Paysafe::Settlement
      )
      subject.get_settlement('6d4f8a01-cd8a-47c1-a361-ab124cd2b617')
    end
  end

  describe '#cancel_settlement' do
    it 'performs a put on a settlement' do
      expect(subject).to receive(:perform_put_with_object).with(
        '/cardpayments/v1/accounts/000/settlements/6d4f8a01-cd8a-47c1-a361-ab124cd2b617',
        { status: 'CANCELLED', test: '' },
        Paysafe::Settlement
      )
      subject.cancel_settlement(settlement_id: '6d4f8a01-cd8a-47c1-a361-ab124cd2b617', test: '')
    end
  end

  describe '#create_refund' do
    it 'performs a post on a settlement refund' do
      expect(subject).to receive(:perform_post_with_object).with(
        '/cardpayments/v1/accounts/000/settlements/6d4f8a01-cd8a-47c1-a361-ab124cd2b617/refunds',
        { merchant_ref_num: 'abc123', amount: 1000, test: '' },
        Paysafe::Settlement
      )
      subject.create_refund(
        settlement_id: '6d4f8a01-cd8a-47c1-a361-ab124cd2b617',
        merchant_ref_num: 'abc123',
        amount: 1000,
        test: ''
      )
    end
  end
end
