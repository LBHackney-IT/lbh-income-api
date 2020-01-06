class AddPaymentRefToCasePriorities < ActiveRecord::Migration[5.2]
  def change
    add_column :case_priorities, :payment_ref, :string
  end
end
