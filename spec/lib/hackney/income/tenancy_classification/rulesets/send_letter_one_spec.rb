require 'rails_helper'

describe 'Send Letter One Rule', type: :feature do
  send_letter_one_condition_matrix = [
    # a valid letter one case
    {
      outcome: :send_letter_one,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 20.0,
      total_payment_amount_in_week: 0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: nil
    },
    # no previous communication
    {
      outcome: :send_letter_one,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 20.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: nil,
      last_communication_action: '',
      eviction_date: '',
      courtdate: nil
    },
    # no previous communication, arrears not high enough
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 0.0,
      total_payment_amount_in_week: -5,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: nil,
      last_communication_action: '',
      eviction_date: '',
      courtdate: nil
    },
    # send letter one, four days ago
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 10.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 4.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
      eviction_date: '',
      courtdate: nil
    },
    # send letter one, four days ago, with the UH code
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 10.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 4.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1_UH,
      eviction_date: '',
      courtdate: nil
    },
    # send alt letter , four days ago
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 10.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 4.days.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::S0A_ALTERNATIVE_LETTER,
      eviction_date: '',
      courtdate: nil
    },
    # active_agreement test
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 10.0,
      is_paused_until: '',
      active_agreement: true,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: nil
    },
    # balance test
    {
      outcome: :send_first_SMS,
      nosp_served_date: nil,
      weekly_rent: 20,
      balance: 8.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: nil
    },
    # last action was send letter two, falls back into send letter one and no action is carried out for  over 3 months
    {
      outcome: :send_letter_one,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 20,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 4.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: '',
      courtdate: nil
    },
    # when the communication is old, but <something else isn't valid>
    {
      outcome: :send_letter_one,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 1000,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 4.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: '',
      courtdate: nil
    },
    {
      outcome: :send_letter_one,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 1000,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: nil,
      last_communication_action: nil,
      eviction_date: '',
      courtdate: nil
    },
    {
      outcome: :no_action,
      nosp_served_date: 8.months.ago.to_date,
      weekly_rent: 5,
      balance: 10,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: nil,
      last_communication_action: nil,
      eviction_date: '',
      courtdate: nil
    },
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 10,
      is_paused_until: '',
      active_agreement: true,
      last_communication_date: 4.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: '',
      courtdate: nil
    },
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 10,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.months.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      eviction_date: '',
      courtdate: nil
    },
    # when a court date is in the past
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 10,
      balance: 20.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: 1.year.ago,
      court_outcome: 'SOMETHING'
    },
    # partial payment in week; arrears not high enough
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 4.0,
      total_payment_amount_in_week: -6,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: nil
    },
    # partial payment in week + missed one week of rent
    {
      outcome: :send_letter_one,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 14.0,
      total_payment_amount_in_week: -6,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: nil
    },
    # full payment in week
    {
      outcome: :send_letter_one,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 10.0,
      total_payment_amount_in_week: -10,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: nil
    },
    # full payment in week but Arrears over 10
    {
      outcome: :send_letter_one,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 20.0,
      total_payment_amount_in_week: -10,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: nil
    },
    # over payment in week but Arrears over 10
    {
      outcome: :send_letter_one,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 20.0,
      total_payment_amount_in_week: -20,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: '',
      eviction_date: '',
      courtdate: nil
    }
  ]

  it_behaves_like 'TenancyClassification', send_letter_one_condition_matrix
end
