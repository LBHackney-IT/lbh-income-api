class AddLatestActiveAgreementDateToCasePriority < ActiveRecord::Migration[5.2]
  def change
    add_column :case_priorities, :latest_active_agreement_date, :datetime
  end
end
