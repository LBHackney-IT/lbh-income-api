class AddBalanceFieldsToAgreementStates < ActiveRecord::Migration[5.2]
  def change
    add_column :agreement_states, :checked_balance, :decimal, precision: 10, scale: 2
    add_column :agreement_states, :expected_balance, :decimal, precision: 10, scale: 2
    add_column :agreement_states, :description, :string
  end
end
