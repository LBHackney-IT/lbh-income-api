require 'rails_helper'

describe 'Send Court Warning Letter Rule', type: :feature do
  court_warning_letter_code = 'IC4'.freeze

  send_court_warning_letter_condition_matrix = [
    {
      outcome: :no_action,
      nosp_served_date: 1.day.ago.to_date,
      weekly_rent: 5,
      balance: 15.0, # 3 * weekly_rent
      collectable_arrears: 15.0, # 3 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: nil,
      eviction_date: nil,
      courtdate: nil
    },
    {
      outcome: :no_action,
      nosp_served_date: 1.day.ago.to_date,
      weekly_rent: 5,
      balance: 50.0, # 10 * weekly_rent
      collectable_arrears: 50.0, # 10 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: nil,
      eviction_date: nil,
      courtdate: nil
    },
    {
      outcome: :no_action,
      nosp_served_date: (Hackney::Domain::Nosp::ACTIVE_TIME + 1.day).ago.to_date,
      weekly_rent: 5,
      balance: 15.0, # 3 * weekly_rent
      collectable_arrears: 15.0, # 3 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: nil,
      eviction_date: nil,
      courtdate: nil
    },
    {
      outcome: :no_action,
      nosp_served_date: (Hackney::Domain::Nosp::ACTIVE_TIME + 1.day).ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      collectable_arrears: 25.0, # 5 * weekly_rent
      is_paused_until: 1.month.from_now.to_date,
      active_agreement: false,
      last_communication_action: nil,
      eviction_date: nil
    },
    {
      outcome: :no_action,
      nosp_served_date: (Hackney::Domain::Nosp::ACTIVE_TIME + 1.day).ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      collectable_arrears: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: true,
      last_communication_action: nil,
      eviction_date: nil,
      courtdate: nil
    },
    {
      outcome: :apply_for_court_date,
      nosp_served_date: (Hackney::Domain::Nosp::ACTIVE_TIME + 1.day).ago.to_date,
      weekly_rent: 5,
      collectable_arrears: 25.0, # 5 * weekly_rent
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: court_warning_letter_code,
      last_communication_date: 3.weeks.ago.to_date,
      eviction_date: nil,
      courtdate: nil
    },
    {
      outcome: :no_action,
      nosp_served_date: (Hackney::Domain::Nosp::ACTIVE_TIME + 1.day).ago.to_date,
      weekly_rent: 5,
      collectable_arrears: 25.0, # 5 * weekly_rent
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: nil,
      eviction_date: 10.days.from_now
    },
    {
      outcome: :no_action,
      nosp_served_date: (Hackney::Domain::Nosp::ACTIVE_TIME + 1.day).ago.to_date,
      weekly_rent: 5,
      balance: 25.0, # 5 * weekly_rent
      collectable_arrears: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: nil,
      eviction_date: 2.weeks.ago
    },
    {
      outcome: :no_action,
      nosp_served_date: (Hackney::Domain::Nosp::ACTIVE_TIME + 1.day).ago.to_date,
      weekly_rent: 5,
      collectable_arrears: 25.0, # 5 * weekly_rent
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: nil,
      eviction_date: 10.days.from_now,
      courtdate: 10.days.from_now
    },
    {
      outcome: :send_court_warning_letter,
      nosp_served_date: (Hackney::Domain::Nosp::ACTIVE_TIME + 1.day).ago.to_date,
      weekly_rent: 5,
      collectable_arrears: 25.0, # 5 * weekly_rent
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: nil,
      eviction_date: nil,
      courtdate: nil
    },
    {
      outcome: :no_action,
      nosp_served_date: (Hackney::Domain::Nosp::ACTIVE_TIME + 1.day).ago.to_date,
      weekly_rent: 5,
      collectable_arrears: 25.0, # 5 * weekly_rent
      balance: 25.0, # 5 * weekly_rent
      is_paused_until: nil,
      active_agreement: false,
      last_communication_action: nil,
      eviction_date: nil,
      court_outcome: nil,
      courtdate: 10.days.from_now
    },
    # missing served date
    {
      outcome: :send_letter_one,
      nosp_served_date: nil,
      weekly_rent: 5,
      collectable_arrears: 25.0, # 5 * weekly_rent
      balance: 25.0, # 5 * weekly_rent
      courtdate: nil
    }
  ]

  it_behaves_like 'TenancyClassification', send_court_warning_letter_condition_matrix
end
