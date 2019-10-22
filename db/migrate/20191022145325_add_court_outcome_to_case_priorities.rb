class AddCourtOutcomeToCasePriorities < ActiveRecord::Migration[5.2]
  def change
    add_column :case_priorities, :court_outcome, :string
  end
end
