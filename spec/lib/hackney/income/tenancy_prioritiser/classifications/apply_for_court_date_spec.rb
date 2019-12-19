require 'rails_helper'

describe 'Apply for Court Date Rule', type: :feature do
  court_warning_letter_code = Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT

  apply_for_court_date_condition_matrix = [
    {
      outcome: :no_action,
      nosps_in_last_year: 1,
      nosp_served_date: 26.days.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: court_warning_letter_code,
      courtdate: '',
      last_communication_date: 1.day.ago.to_date,
      eviction_date: nil
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 1,
      nosp_served_date: 26.days.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: court_warning_letter_code,
      courtdate: '',
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: nil
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_served_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: true,
      last_communication_action: court_warning_letter_code,
      courtdate: '',
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: nil
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 1,
      nosp_served_date: 29.days.ago.to_date,
      weekly_rent: 5,
      balance: 10.0, # 2 * weekly_rent
      is_paused_until: nil,
      active_agreement: true,
      last_communication_action: court_warning_letter_code,
      courtdate: '',
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: nil
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 1,
      nosp_served_date: 29.days.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: 1.day.from_now.to_date,
      active_agreement: true,
      last_communication_action: court_warning_letter_code,
      courtdate: '',
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: nil
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 1,
      nosp_served_date: 29.days.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: true,
      last_communication_action: 'ZR3', # ZR3 is NOSP is served over 28 days ago.
      courtdate: '',
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: nil
    },
    {
      outcome: :apply_for_court_date,
      nosps_in_last_year: 1,
      nosp_served_date: 29.days.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: true,
      last_communication_action: court_warning_letter_code,
      courtdate: '',
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: nil
    },
    {
      outcome: :apply_for_court_date,
      nosps_in_last_year: 1,
      nosp_served_date: 29.days.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: court_warning_letter_code,
      courtdate: '',
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: nil
    },
    {
      outcome: :update_court_outcome_action,
      nosps_in_last_year: 1,
      nosp_served_date: 29.days.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: court_warning_letter_code,
      courtdate: 5.days.ago.to_date,
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: nil
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 1,
      nosp_served_date: 29.days.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: court_warning_letter_code,
      courtdate: 5.days.ago.to_date,
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: 2.weeks.from_now
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 1,
      nosp_served_date: 29.days.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: court_warning_letter_code,
      courtdate: 5.days.ago.to_date,
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: 1.month.ago
    },
    {
      outcome: :update_court_outcome_action,
      nosps_in_last_year: 1,
      nosp_served_date: 29.days.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: court_warning_letter_code,
      courtdate: 5.days.ago.to_date,
      last_communication_date: 1.week.ago.to_date,
      eviction_date: nil
    },
    {
      outcome: :apply_for_court_date,
      nosps_in_last_year: 1,
      nosp_served_date: 29.days.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: court_warning_letter_code,
      courtdate: 2.weeks.from_now.to_date,
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: nil
    }
  ]

  it_behaves_like 'TenancyClassification', apply_for_court_date_condition_matrix
end
