class BalanceCurrencyField < ActiveRecord::Migration[5.2]
  def change
    change_column :case_priorities, :balance, :decimal, precision: 10, scale: 2
  end
end
