class AddNospServedDateToCasePriorities < ActiveRecord::Migration[5.2]
  def change
    add_column :case_priorities, :nosp_served_date, :datetime
  end
end
