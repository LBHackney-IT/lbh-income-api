class AddCourtdateToCasePriorities < ActiveRecord::Migration[5.2]
  def change
    add_column :case_priorities, :courtdate, :datetime
  end
end
