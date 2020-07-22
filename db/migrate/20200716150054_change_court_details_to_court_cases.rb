class ChangeCourtDetailsToCourtCases < ActiveRecord::Migration[5.2]
  def change
    drop_table :court_details

    create_table :court_cases do |t|
      t.datetime :court_decision_date
      t.text :court_outcome
      t.decimal :balance_at_outcome_date
      t.string :tenancy_ref, null: false

      t.timestamps
    end

    add_belongs_to :agreements, :court_case, foreign_key: true
  end
end
