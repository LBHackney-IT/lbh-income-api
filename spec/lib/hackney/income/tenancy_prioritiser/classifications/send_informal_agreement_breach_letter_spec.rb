require 'rails_helper'

describe 'Send Informal Agreement Breach Letter Rule examples' do
  base_example = {
    outcome: :send_informal_agreement_breach_letter,
    active_agreement: false,
    balance: 5,
    expected_balance: 10,
    breach_agreement_date: 4.days.ago,
    courtdate: nil,
    latest_active_agreement_date: 7.days.ago,
    last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
    last_communication_date: 1.month.ago,
    number_of_broken_agreements: 1
  }
  examples = [
    base_example,
    base_example.merge(
      desription: 'when the court date is in the past',
      outcome: :no_action,
      courtdate: 5.days.ago,
      court_outcome: 'AGR'
    ),
    base_example.merge(
      desription: 'when the expected balance is less than the balance',
      outcome: :no_action,
      balance: 10,
      expected_balance: 5
    ),
    base_example.merge(
      desription: 'when there is an active agreement',
      outcome: :no_action,
      active_agreement: true
    ),
    base_example.merge(
      desription: 'when the agreement date is less than 3 days ago',
      outcome: :no_action,
      breach_agreement_date: 2.days.ago
    )
  ]
  it_behaves_like 'TenancyClassification', examples
end
