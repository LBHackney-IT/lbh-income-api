class FixPrecisionWhereMoneyStored < ActiveRecord::Migration[5.2]
  def up
    change_column :agreements, :starting_balance, :decimal, precision: 10, scale: 2
    change_column :agreements, :amount, :decimal, precision: 10, scale: 2
    change_column :court_cases, :balance_at_outcome_date, :decimal, precision: 10, scale: 2
    change_column :case_priorities, :expected_balance, :decimal, precision: 10, scale: 2
  end

  def down
    change_column :agreements, :starting_balance, :decimal, precision: 10
    change_column :agreements, :amount, :decimal, precision: 10
    change_column :court_cases, :balance_at_outcome_date, :decimal, precision: 10
    change_column :case_priorities, :expected_balance, :decimal, precision: 10
  end
end
