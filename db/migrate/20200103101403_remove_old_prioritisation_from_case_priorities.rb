class RemoveOldPrioritisationFromCasePriorities < ActiveRecord::Migration[5.2]
  def up
    change_table :case_priorities do |t|
      t.remove :priority_band,
               :priority_score,
               :balance_contribution,
               :days_in_arrears_contribution,
               :number_of_broken_agreements_contribution,
               :nosp_served_contribution,
               :days_since_last_payment_contribution,
               :payment_amount_delta_contribution,
               :payment_date_delta_contribution,
               :active_agreement_contribution,
               :broken_court_order_contribution,
               :active_nosp_contribution,
               :payment_amount_delta,
               :payment_date_delta
    end
  end
end
