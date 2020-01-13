require 'rails_helper'

describe 'Send Court Breach Letter Rule', type: :feature do
  court_breach_letter_code = Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT
  court_warning_letter_code = Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT

  send_court_breach_letter_condition_matrix = [
    {
      outcome: :court_breach_visit,
      nosps_in_last_year: 0,
      weekly_rent: 5,
      is_paused_until: nil,
      balance: 15.0, # 3 * weekly_rent
      active_agreement: false,
      last_communication_action: court_breach_letter_code,
      last_communication_date: Date.today + 21
    },
    {
      outcome: :send_letter_one,
      nosps_in_last_year: 0,
      weekly_rent: 5,
      is_paused_until: nil,
      balance: 15.0, # 3 * weekly_rent
      active_agreement: false,
      last_communication_action: court_breach_letter_code,
      last_communication_date: 20.weeks.ago.to_date
    },
    {
      outcome: :court_breach_visit,
      nosps_in_last_year: 0,
      weekly_rent: 5,
      is_paused_until: nil,
      balance: 15.0, # 3 * weekly_rent
      active_agreement: false,
      last_communication_action: court_breach_letter_code,
      last_communication_date: 3.months.ago
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      weekly_rent: 5,
      is_paused_until: nil,
      balance: 15.0, # 3 * weekly_rent
      active_agreement: false,
      last_communication_action: court_warning_letter_code,
      last_communication_date: Date.today + 21
    },
    {
      outcome: :court_breach_visit,
      nosps_in_last_year: 0,
      weekly_rent: 5,
      is_paused_until: nil,
      balance: 15.0, # 3 * weekly_rent
      active_agreement: false,
      last_communication_action: court_breach_letter_code,
      last_communication_date: Date.today + 21
    },
    {
      outcome: :send_letter_one,
      nosps_in_last_year: 0,
      weekly_rent: 5,
      is_paused_until: nil,
      balance: 15.0, # 3 * weekly_rent
      active_agreement: false,
      last_communication_action: court_breach_letter_code,
      last_communication_date: Date.today - 200
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      weekly_rent: 5,
      is_paused_until: nil,
      balance: 15.0, # 3 * weekly_rent
      active_agreement: false,
      last_communication_action: court_warning_letter_code,
      last_communication_date: Date.today + 21
    },
    {
      outcome: :send_letter_one,
      nosps_in_last_year: 0,
      weekly_rent: 5,
      is_paused_until: nil,
      balance: 15.0, # 3 * weekly_rent
      active_agreement: false,
      last_communication_action: '',
      last_communication_date: Date.today + 21
    }
  ]

  it_behaves_like 'TenancyClassification', send_court_breach_letter_condition_matrix
end
