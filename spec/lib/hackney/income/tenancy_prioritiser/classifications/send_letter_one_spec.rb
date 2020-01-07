require 'rails_helper'

describe 'Send Letter One Rule', type: :feature do
  send_letter_one_condition_matrix = [
    # a valid letter one case
    {
      outcome: :send_letter_one,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 6.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: ''
    },
    # no previous communication
    {
      outcome: :send_letter_one,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 6.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: nil,
      last_communication_action: '',
      eviction_date: '',
      courtdate: ''
    },
    # no previous communication, arrears not high enough
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 0.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: nil,
      last_communication_action: '',
      eviction_date: '',
      courtdate: ''
    },
    # send letter one, four days ago
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 6.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 4.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
      eviction_date: '',
      courtdate: ''
    },
    # send letter one, four days ago, with the UH code
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 6.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 4.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1_UH,
      eviction_date: '',
      courtdate: ''
    },
    # active_agreement test
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 6.0,
      is_paused_until: '',
      active_agreement: true,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: ''
    },
    # balance test
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 4.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: ''
    },
    # last action was send letter two, falls back into send letter one and no action is carried out for  over 3 months
    {
      outcome: :send_letter_one,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 6,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 4.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: '',
      courtdate: ''
    },
    # when the communication is old, but <something else isn't valid>
    {
      outcome: :send_letter_one,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 1000,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 4.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: '',
      courtdate: ''
    },
    {
      outcome: :send_letter_one,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 1000,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: nil,
      last_communication_action: nil,
      eviction_date: '',
      courtdate: ''
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 1,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 10,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: nil,
      last_communication_action: nil,
      eviction_date: '',
      courtdate: ''
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 10,
      is_paused_until: '',
      active_agreement: true,
      last_communication_date: 4.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: '',
      courtdate: ''
    },
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 6,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: '',
      courtdate: ''
    }
  ]

  it_behaves_like 'TenancyClassification', send_letter_one_condition_matrix
end
