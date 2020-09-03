class RemoveOldAgreementFields < ActiveRecord::Migration[5.2]
  def up
    change_table :case_priorities do |t|
      t.remove :latest_active_agreement_date,
               :breach_agreement_date,
               :number_of_broken_agreements,
               :expected_balance,
               :broken_court_order,
               :active_agreement
    end
  end
end
