require 'rails_helper'

describe '"Court Breach - No Payment" examples' do
  visit_made_action_code = Hackney::Tenancy::ActionCodes::VISIT_MADE
  adjourned_action_code = Hackney::Tenancy::ActionCodes::ADJOURNED_ON_TERMS_COURT_OUTCOME

  base_example = {
    outcome: :court_breach_no_payment,
    weekly_rent: 5,
    is_paused_until: nil,
    balance: 15.0,
    active_agreement: false,
    courtdate: 7.days.ago.to_date,
    court_outcome: 'Jail',
    last_communication_action: visit_made_action_code,
    last_communication_date: 8.days.ago.to_date
  }

  examples = [
    base_example,
    base_example.merge(
      description: 'when the last_communication_date is 7 days ago',
      outcome: :court_breach_no_payment,
      last_communication_action: visit_made_action_code,
      last_communication_date: 7.days.ago.to_date
    ),
    base_example.merge(
      description: 'when the last_communication_action NOT a visit_made_action_code',
      outcome: :send_letter_one,
      last_communication_action: adjourned_action_code,
      last_communication_date: 7.days.ago.to_date
    ),
    base_example.merge(
      description: 'when there is no court outcome',
      outcome: :update_court_outcome_action,
      court_outcome: '',
      last_communication_action: visit_made_action_code,
      last_communication_date: 7.days.ago.to_date
    ),
    base_example.merge(
      description: 'when there is no courtdate',
      outcome: :send_letter_one,
      courtdate: nil,
      last_communication_action: visit_made_action_code,
      last_communication_date: 7.days.ago.to_date
    ),
    base_example.merge(
      description: 'when the court date is in the future',
      outcome: :no_action,
      courtdate: 3.months.from_now.to_date,
      last_communication_action: visit_made_action_code,
      last_communication_date: 7.days.ago.to_date
    ),
    base_example.merge(
      description: 'with no last_communication_action',
      outcome: :send_letter_one,
      last_communication_action: '',
      last_communication_date: 8.days.ago.to_date
    ),
    base_example.merge(
      description: 'with no last_communication_date',
      outcome: :send_letter_one,
      last_communication_action: visit_made_action_code,
      last_communication_date: ''
    ),
    base_example.merge(
      description: 'when the last_communication_date is not greater or equal to 7 days',
      outcome: :send_letter_one,
      last_communication_action: visit_made_action_code,
      last_communication_date: 6.days.ago.to_date
    )
  ]

  include_examples 'TenancyClassification', examples
end
