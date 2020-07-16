class AddBalanceWithoutSumOfWeeksTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :case_priorities, :collectable_arrears, :decimal, precision: 10, scale: 2
  end
end
