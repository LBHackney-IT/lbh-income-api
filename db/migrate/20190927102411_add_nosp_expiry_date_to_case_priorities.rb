class AddNospExpiryDateToCasePriorities < ActiveRecord::Migration[5.2]
  def change
    add_column :case_priorities, :nosp_expiry_date, :datetime
  end
end
