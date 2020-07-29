class UpdateCourtCaseModel < ActiveRecord::Migration[5.2]
  def change
    add_column :court_cases, :strike_out_date, :datetime, null: false
    add_column :court_cases, :created_by, :string, null: false
  end
end
