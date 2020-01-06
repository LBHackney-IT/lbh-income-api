require 'rails_helper'

describe '"Apply for Court Date" examples' do
  court_warning_letter_code = Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT

  base_example = {
    outcome: :apply_for_court_date,
    nosps_in_last_year: 1,
    nosp_served_date: 29.days.ago.to_date,
    weekly_rent: 5,
    balance: 25.0,
    last_communication_action: court_warning_letter_code,
    last_communication_date: 3.weeks.ago.to_date,
    courtdate: ''
  }

  examples = [
    base_example,
    base_example.merge(
      description: 'with an active agreement',
      outcome: :apply_for_court_date,
      active_agreement: true
    ),
    base_example.merge(
      description: 'with a recent court warning letter',
      outcome: :no_action,
      last_communication_action: court_warning_letter_code,
      last_communication_date: 1.week.ago.to_date
    ),
    base_example.merge(
      description: 'with a nosp served less than 28 days ago',
      outcome: :no_action,
      nosp_served_date: 26.days.ago.to_date
    ),
    base_example.merge(
      description: 'with no nosps served in the last year',
      outcome: :no_action,
      nosps_in_last_year: 0
    ),
    base_example.merge(
      description: 'with an active agreement',
      outcome: :apply_for_court_date,
      active_agreement: true
    ),
    base_example.merge(
      description: 'with arrears lower than four weeks rent',
      outcome: :no_action,
      weekly_rent: 5,
      balance: 10
    ),
    base_example.merge(
      description: 'when paused',
      outcome: :no_action,
      is_paused_until: 1.day.from_now.to_date
    ),
    base_example.merge(
      description: 'with a ZR3 (old NOSP) last communication and an active agreement',
      outcome: :no_action,
      last_communication_action: 'ZR3', # ZR3 is NOSP is served over 28 days ago.
      active_agreement: true
    ),
    base_example.merge(
      description: 'with a past court date',
      outcome: :apply_for_court_date,
      courtdate: ''
    ),
    base_example.merge(
      description: 'with an evicition date',
      outcome: :no_action,
      eviction_date: 1.day.from_now.to_date
    ),
    base_example.merge(
      description: 'with an eviction date (past or upcoming)',
      outcome: :no_action,
      eviction_date: 2.weeks.from_now
    )
  ]

  include_examples 'TenancyClassification', examples
end
