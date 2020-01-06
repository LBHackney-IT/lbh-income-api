class AddExpectedBalanceToCasePriority < ActiveRecord::Migration[5.2]
  def change
    add_column :case_priorities, :expected_balance, :decimal
  end
end
