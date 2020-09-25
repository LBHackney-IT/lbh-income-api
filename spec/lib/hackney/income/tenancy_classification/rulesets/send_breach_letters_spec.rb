require 'rails_helper'

describe 'Various "Send breach letter" examples (new)' do
  base_example = {
    outcome: :send_informal_agreement_breach_letter,
    most_recent_agreement: {
      start_date: 1.week.ago,
      breached: true
    }
  }

  examples = [
    base_example,
    base_example.deep_merge(
      description: 'with an unbreached agreement',
      outcome: :no_action,
      most_recent_agreement: { breached: false }
    ),
    base_example.deep_merge(
      description: 'with an undated agreement',
      outcome: :no_action,
      most_recent_agreement: { start_date: nil }
    ),
    base_example.deep_merge(
      description: 'with a court date after the agreement',
      outcome: :send_informal_agreement_breach_letter,
      courtdate: 1.day.ago,
      court_outcome: 'outcome with no court agreement'
    ),
    base_example.merge(
      description: 'with a court date before the agreement',
      outcome: :address_court_agreement_breach,
      courtdate: 2.weeks.ago,
      court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE
    ),
    base_example.merge(
      description: 'with a court date more than three months before the agreement',
      outcome: :address_court_agreement_breach,
      courtdate: 4.months.ago,
      court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE
    ),
    base_example.merge(
      description: 'with a last_communication_action which is visit made',
      outcome: :address_court_agreement_breach,
      courtdate: 4.months.ago,
      court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE,
      last_communication_action: Hackney::Tenancy::ActionCodes::VISIT_MADE
    ),
    base_example.deep_merge(
      description: 'with a court date and agreement start date on the same day',
      outcome: :address_court_agreement_breach,
      courtdate: 2.weeks.ago,
      court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE,
      most_recent_agreement: {
        start_date: 2.weeks.ago,
        breached: true
      }
    ),
    base_example.deep_merge(
      description: 'with a court date and court agreement start date before court date',
      outcome: :check_data,
      courtdate: 2.weeks.ago,
      court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE,
      most_recent_agreement: {
        start_date: 3.weeks.ago,
        breached: true
      }
    ),
    base_example.deep_merge(
      description: 'with the last communication being a court breach letter',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_BREACH_LETTER_SENT,
      last_communication_date: 6.months.ago
    )
  ]

  include_examples 'TenancyClassification', examples
end
