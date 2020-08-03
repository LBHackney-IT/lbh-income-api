class UpdateCourtCaseColumns < ActiveRecord::Migration[5.2]
  def up
    rename_column :court_cases, :court_decision_date, :court_date
    rename_column :court_cases, :balance_at_outcome_date, :balance_on_court_outcome_date
    change_column_null :court_cases, :court_date, false
    change_column_null :court_cases, :strike_out_date, true
  end

  def down
    change_column_null :court_cases, :strike_out_date, false
    change_column_null :court_cases, :court_date, true
    rename_column :court_cases, :balance_on_court_outcome_date, :balance_at_outcome_date
    rename_column :court_cases, :court_date, :court_decision_date
  end
end
