require 'rails_helper'

describe '"Update court outcome" examples' do
  base_example = {
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
  }

  examples = [
    base_example,
    base_example.merge(
      description: 'with a court date in the past by 100 days',
      outcome: :update_court_outcome_action,
      courtdate: Date.today - 100.days
    ),
    base_example.merge(
      description: 'with a court date in the past by 100 days',
      outcome: :update_court_outcome_action,
      courtdate: Date.today - 2.days
    ),
    base_example.merge(
      description: 'with a court date 14 days in the future',
      outcome: :no_action,
      courtdate: Date.today + 14.days
    ),
    base_example.merge(
      description: 'with a court date 14 days in the future and a court outcome has been reached',
      outcome: :no_action,
      court_outcome: 'Outcome reached',
      courtdate: Date.today + 14.days
    ),
    base_example.merge(
      description: 'with a last communication action of sms sent',
      outcome: :no_action,
      court_outcome: 'Outcome reached',
      last_communication_action: Hackney::Tenancy::ActionCodes::MANUAL_SMS_ACTION_CODE,
      courtdate: Date.today + 14.days
    ),
    base_example.merge(
      description: 'with a court date 14 days in the past and a court outcome has been reached',
      outcome: :no_action,
      court_outcome: 'Outcome reached',
      courtdate: Date.today - 14.days
    ),
    base_example.merge(
      description: 'with no court date set and a court outcome has been reached',
      outcome: :no_action,
      court_outcome: 'Outcome reached',
      courtdate: ''
    ),
    base_example.merge(
      description: 'with no court date or court outcome present',
      outcome: :no_action,
      court_outcome: '',
      courtdate: ''
    ),
    base_example.merge(
      description: 'with a court outcome and eviction date in the furture',
      outcome: :no_action,
      court_outcome: 'Jail',
      courtdate: '',
      eviction_date: Date.today + 367.days
    )
  ]

  include_examples 'TenancyClassification', examples
end
