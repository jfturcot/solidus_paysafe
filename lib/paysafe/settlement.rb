# frozen_string_literal: true

require 'paysafe/result'

module Paysafe
  class Settlement < Result
    attributes :id, :merchant_ref_num, :amount, :dup_check, :available_to_refund, :txn_time, :status
  end
end
