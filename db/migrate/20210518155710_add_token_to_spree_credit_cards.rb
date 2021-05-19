class AddTokenToSpreeCreditCards < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_credit_cards, :token, :string
  end
end
