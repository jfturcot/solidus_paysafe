# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Paysafe::Settlement do
  it { is_expected.to respond_to(:id) }
  it { is_expected.to respond_to(:merchant_ref_num) }
  it { is_expected.to respond_to(:amount) }
  it { is_expected.to respond_to(:dup) }
  it { is_expected.to respond_to(:available_to_refund) }
  it { is_expected.to respond_to(:txn_time) }
  it { is_expected.to respond_to(:status) }
end
