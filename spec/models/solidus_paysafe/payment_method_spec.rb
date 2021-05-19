# frozen_string_literal: true

require 'spec_helper'

describe SolidusPaysafe::PaymentMethod do
  subject(:payment_method) { create(:paysafe_payment_method) }

  describe "gateway" do
    it "returns a SolidusPaysafe::Gateway instance" do
      expect(payment_method.gateway).to be_a SolidusPaysafe::Gateway
    end
  end

  describe "partial_name" do
    it "returns paysafe" do
      expect(payment_method.partial_name).to eql 'paysafe'
    end
  end
end
