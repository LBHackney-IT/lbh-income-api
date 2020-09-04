class AddVariablePaymentAgreementFields < ActiveRecord::Migration[5.2]
  def up
    add_column :agreements, :initial_payment_amount, :decimal, precision: 10, scale: 2
    add_column :agreements, :initial_payment_date, :datetime
  end
end
