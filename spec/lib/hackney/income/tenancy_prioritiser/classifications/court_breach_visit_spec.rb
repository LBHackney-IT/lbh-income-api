require 'rails_helper'

describe 'Send Court Breach Letter Rule', type: :feature do
  court_breach_letter_code = Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT
  court_warning_letter_code = Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT

  base_example = {
    outcome: :court_breach_visit,
    nosps_in_last_year: 0,
    weekly_rent: 5,
    is_paused_until: nil,
    balance: 15.0, # 3 * weekly_rent
    active_agreement: false,
    last_communication_action: court_breach_letter_code,
    last_communication_date: Date.today + 21
  }

  examples = [
    base_example,
    base_example.merge(
      description: 'with a valid last_communication_action',
      outcome: :court_breach_visit,
      last_communication_action: court_breach_letter_code,
      last_communication_date: Date.today + 21
    ),
    base_example.merge(
      description: 'with a date outside of 3 months',
      outcome: :send_letter_one,
      last_communication_action: court_breach_letter_code,
      last_communication_date: Date.today - 420
    ),
    base_example.merge(
      description: 'with a last_communication_action which is NOT a court_breach_letter_code',
      outcome: :no_action,
      last_communication_action: court_warning_letter_code,
      last_communication_date: Date.today + 21
    )
  ]

  include_examples 'TenancyClassification', examples
end
