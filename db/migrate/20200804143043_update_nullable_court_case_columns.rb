class UpdateNullableCourtCaseColumns < ActiveRecord::Migration[5.2]
  def change
    change_column_null :court_cases, :court_date, true
    remove_column :court_cases, :created_by, :string
  end
end
