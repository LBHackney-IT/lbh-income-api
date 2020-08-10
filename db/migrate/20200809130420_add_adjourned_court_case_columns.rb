class AddAdjournedCourtCaseColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :court_cases, :terms, :boolean
    add_column :court_cases, :disrepair_counter_claim, :boolean
  end
end
