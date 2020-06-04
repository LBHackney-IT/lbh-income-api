require 'rails_helper'

describe 'Send Letter Two Rule', type: :feature do
  letter_1_in_arrears_sent_code = Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1

  send_letter_two_condition_matrix = [
    {
      outcome: :send_letter_two,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 20,
      total_payment_amount_in_week: 0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 14.days.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: '',
      courtdate: nil
    },
    # balance test
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 19.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 15.days.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: '',
      courtdate: nil
    },
    # nosps in last year test
    {
      outcome: :no_action,
      nosp_served_date: 8.months.ago,
      weekly_rent: 5,
      balance: 20.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: '',
      courtdate: nil
    },
    # last communication date tests
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 20.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 13.days.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: '',
      courtdate: nil
    },
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 20.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 3.months.from_now.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: '',
      courtdate: nil
    },
    # last communication action test
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 20.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      eviction_date: '',
      courtdate: nil
    },
    {
      outcome: :send_letter_two,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 20.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: '',
      courtdate: nil
    },
    {
      outcome: :send_letter_two,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 20.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1_UH,
      eviction_date: '',
      courtdate: nil
    },
    # eviction date test
    {
      outcome: :no_action,
      nosp_served_date: nil,
      weekly_rent: 5,
      balance: 20.0,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: 5.days.from_now.to_date
    },
    # active agreement
    {
      outcome: :no_action,
      weekly_rent: 5,
      balance: 20.0,
      active_agreement: true,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      courtdate: nil
    },
    # court date in past
    {
      outcome: :no_action,
      nosps_in_last_year: 0,
      nosp_expiry_date: '',
      weekly_rent: 5,
      balance: 20,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 2.weeks.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
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
      last_communication_date: 14.days.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: '',
      courtdate: nil
    },
    # partial payment in week + missed one week of rent
    {
      outcome: :send_letter_two,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 14.0,
      total_payment_amount_in_week: -6,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 14.days.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: '',
      courtdate: nil
    },
    # full payment in week
    {
      outcome: :send_letter_two,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 10.0,
      total_payment_amount_in_week: -10,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 14.days.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: '',
      courtdate: nil
    },
    # full payment in week but Arrears over 10
    {
      outcome: :send_letter_two,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 20.0,
      total_payment_amount_in_week: -10,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 14.days.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: '',
      courtdate: nil
    },
    # over payment in week but Arrears over 10
    {
      outcome: :send_letter_two,
      nosp_served_date: nil,
      weekly_rent: 10,
      balance: 20.0,
      total_payment_amount_in_week: -20,
      is_paused_until: '',
      active_agreement: false,
      last_communication_date: 14.days.ago.to_date,
      last_communication_action: letter_1_in_arrears_sent_code,
      eviction_date: '',
      courtdate: nil
    }
  ]

  it_behaves_like 'TenancyClassification', send_letter_two_condition_matrix
end
