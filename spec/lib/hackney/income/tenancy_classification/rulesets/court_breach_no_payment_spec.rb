require 'rails_helper'

describe '"Court Breach - No Payment" examples' do
  base_example = {
    outcome: :court_breach_no_payment,
    weekly_rent: 5,
    is_paused_until: nil,
    collectable_arrears: 15.0,
    balance: 15.0,
    nosp_served_date: 8.months.ago.to_date,
    courtdate: 14.days.ago.to_date,
    court_outcome: 'Jail',
    last_communication_action: Hackney::Tenancy::ActionCodes::VISIT_MADE,
    last_communication_date: 8.days.ago.to_date,
    days_since_last_payment: 8,
    most_recent_agreement: {
      start_date: 1.week.ago,
      breached: true
    }
  }

  examples = [
    base_example,
    base_example.deep_merge(
      description: 'when the days_since_last_payment is less than 7 days ago',
      outcome: :no_action,
      days_since_last_payment: 7
    ),
    base_example.deep_merge(
      description: 'when the last_communication_action NOT a visit_made_action_code',
      outcome: :send_court_agreement_breach_letter,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT
    ),
    base_example.deep_merge(
      description: 'when there is no agreement',
      outcome: :no_action,
      most_recent_agreement: nil
    ),
    base_example.deep_merge(
      description: 'when there is no breached agreement',
      outcome: :no_action,
      most_recent_agreement: {
        breached: false
      }
    ),
    base_example.deep_merge(
      description: 'when there is no courtdate',
      outcome: :check_data,
      skip_v1_test: true,
      courtdate: nil
    ),
    base_example.deep_merge(
      description: 'when the court date is in the future',
      outcome: :no_action,
      courtdate: 3.months.from_now.to_date
    ),
    base_example.deep_merge(
      description: 'when the last_communication_date is not greater or equal to 7 days',
      outcome: :no_action,
      last_communication_date: 6.days.ago.to_date
    )
  ]

  include_examples 'TenancyClassification', examples
end
