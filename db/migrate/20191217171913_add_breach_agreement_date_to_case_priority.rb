class AddBreachAgreementDateToCasePriority < ActiveRecord::Migration[5.2]
  def change
    add_column :case_priorities, :breach_agreement_date, :datetime
  end
end
