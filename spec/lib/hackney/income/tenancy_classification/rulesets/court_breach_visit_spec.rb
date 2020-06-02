require 'rails_helper'

describe 'Send Court Breach Letter Rule', type: :feature do
  base_example = {
    outcome: :court_breach_visit,
    weekly_rent: 5,
    is_paused_until: nil,
    balance: 15.0, # 3 * weekly_rent
    active_agreement: false,
    court_outcome: 'Jail',
    last_communication_action: Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT,
    last_communication_date: 2.weeks.ago,
    courtdate: 14.days.ago.to_date,
    nosp_served_date: 8.months.ago.to_date,
    most_recent_agreement: {
      start_date: 1.week.ago,
      breached: true
    }
  }

  examples = [
    base_example,
    base_example.merge(
      description: 'with a date outside of 3 months',
      outcome: :no_action,
      last_communication_date: 4.months.ago
    ),
    base_example.merge(
      description: 'with a last_communication_action which is NOT a court_breach_letter_code',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::VISIT_MADE
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
    )
  ]

  include_examples 'TenancyClassification', examples
end
