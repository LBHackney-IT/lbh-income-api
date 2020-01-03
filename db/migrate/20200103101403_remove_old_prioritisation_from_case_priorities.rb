class RemoveOldPrioritisationFromCasePriorities < ActiveRecord::Migration[5.2]
  def change
    remove_column :case_priorities, :priority_band, :string
    remove_column :case_priorities, :priority_score, :integer
    remove_column :case_priorities, :balance_contribution, :decimal
    remove_column :case_priorities, :days_in_arrears_contribution, :decimal
    remove_column :case_priorities, :number_of_broken_agreements_contribution, :decimal
    remove_column :case_priorities, :nosp_served_contribution, :decimal
    remove_column :case_priorities, :days_since_last_payment_contribution, :decimal
    remove_column :case_priorities, :payment_amount_delta_contribution, :decimal
    remove_column :case_priorities, :payment_date_delta_contribution, :decimal
    remove_column :case_priorities, :umber_of_broken_agreements_contribution, :decimal
    remove_column :case_priorities, :active_agreement_contribution, :decimal
    remove_column :case_priorities, :broken_court_order_contribution, :decimal
    remove_column :case_priorities, :osp_served_contribution, :decimal
    remove_column :case_priorities, :active_nosp_contribution, :decimal
  end
end
