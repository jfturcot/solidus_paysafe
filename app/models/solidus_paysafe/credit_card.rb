# frozen_string_literal: true

module SolidusPaysafe
  class CreditCard < ::Spree::CreditCard
    before_validation :set_token

    validates :token, presence: true

    private

    # Sets the token field from the encrypted_data.
    def set_token
      self.token ||= encrypted_data
    end

    def require_card_numbers?
      false
    end
  end
end
