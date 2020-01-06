require 'rails_helper'

describe 'Send NOSP Rule', type: :feature do
  send_nosp_condition_matrix = [
    # out of date nosp, out of arrears, no recent activity
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: 1.month.ago.to_date,
      weekly_rent: 5,
      balance: 0,
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: nil,
      eviction_date: 1.month.from_now
    },
    # NOT CONFIDENT THIS TEST IS CORRECT (not :send_letter_one?)
    # out of date nosp, heavily in arrears, no recent activity
    {
      outcome: :send_NOSP,
      nosps_in_last_year: 0,
      nosp_expiry_date: 1.month.ago.to_date,
      weekly_rent: 5,
      balance: 50.0,
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: nil,
      court_outcome: 'Jail'
    },
    # out of date nosp, heavily in arrears, recent letter 2
    {
      outcome: :send_NOSP,
      nosps_in_last_year: 0,
      nosp_expiry_date: 1.month.ago.to_date,
      weekly_rent: 5,
      balance: 50.0,
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 2.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      court_outcome: 'Jail'
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 1,
      nosp_expiry_date: 8.months.from_now.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 2.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: nil,
      court_outcome: 'Jail'
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: 1.month.ago.to_date,
      weekly_rent: 5,
      balance: 10.0, # 2 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 2.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: nil,
      court_outcome: 'Jail'
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: 1.month.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: 1.month.from_now,
      active_agreement: false,
      last_communication_date: 2.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: nil
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 5.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: nil,
      court_outcome: 'Jail'
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: 2.weeks.ago
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: 1.week.from_now
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: 5.weeks.from_now,
      courtdate: 2.weeks.from_now
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: true,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: nil,
      court_outcome: 'Jail'
    },
    {
      outcome: :send_NOSP,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: nil,
      court_outcome: 'Jail'
    },
    {
      outcome: :send_NOSP,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH,
      eviction_date: nil,
      court_outcome: 'Jail'
    },
    {
      outcome: :send_NOSP,
      nosps_in_last_year: 0,
      nosp_expiry_date: 1.month.ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 7.months.ago.to_date,
      last_communication_action: 'ANYTHING',
      eviction_date: nil,
      court_outcome: 'Jail'
    },
    {
      outcome: :send_NOSP,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: nil,
      court_outcome: 'Jail'
    },
    {
      outcome: :send_NOSP,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH,
      eviction_date: nil,
      court_outcome: 'Jail'
    },
    {
      outcome: :send_NOSP,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: nil,
      court_outcome: 'Jail'
    },
    {
      outcome: :send_NOSP,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH,
      eviction_date: nil,
      court_outcome: 'Jail'
    },
    {
      outcome: :update_court_outcome_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: nil,
      court_outcome: nil,
      courtdate: 2.months.ago
    },
    {
      outcome: :send_NOSP,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: nil,
      court_outcome: 'Jail',
      courtdate: 2.months.ago
    },
    {
      outcome: :send_NOSP,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_date: 8.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH,
      eviction_date: nil,
      court_outcome: 'Jail',
      courtdate: 2.months.ago
    }
  ]

  it_behaves_like 'TenancyClassification', send_nosp_condition_matrix
end
