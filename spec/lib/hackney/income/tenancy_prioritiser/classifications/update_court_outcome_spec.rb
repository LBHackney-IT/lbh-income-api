require 'rails_helper'

describe 'Update court outcome', type: :feature do
  update_court_outcome_condition_matrix = [
    {
      outcome: :update_court_outcome_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 10,
      balance: 6,
      is_paused_until: '',
      active_agreement: true,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      court_outcome: '',
      courtdate: Date.today - 14.days
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 10,
      balance: 6,
      is_paused_until: '',
      active_agreement: true,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      court_outcome: '',
      courtdate: Date.today + 14.days
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 10,
      balance: 4.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::MANUAL_SMS_ACTION_CODE,
      eviction_date: '',
      court_outcome: '',
      courtdate: Date.today + 14.days
    }
  ]

  it_behaves_like 'TenancyClassification', update_court_outcome_condition_matrix
end
