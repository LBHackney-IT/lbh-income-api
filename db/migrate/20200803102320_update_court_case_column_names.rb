class UpdateCourtCaseColumnNames < ActiveRecord::Migration[5.2]
  def change
    rename_column :court_cases, :court_decision_date, :date_of_court_decision
    rename_column :court_cases, :balance_at_outcome_date, :balance_on_court_outcome_date
  end
end
