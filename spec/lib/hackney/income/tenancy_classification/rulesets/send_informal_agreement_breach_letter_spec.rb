require 'rails_helper'

describe 'Various "Send informal breach letter" examples (new)' do
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
      description: 'with an valid NOSP',
      nosp_served_date: 1.months.ago,
      outcome: :no_action
    ),
    base_example.deep_merge(
      description: 'with an invalid NOSP',
      nosp_served_date: 5.years.ago
    ),
    base_example.deep_merge(
      description: 'with an undated agreement',
      outcome: :no_action,
      most_recent_agreement: { start_date: nil }
    ),
    base_example.merge(
      description: 'with a court date before the court agreement',
      outcome: :address_court_agreement_breach,
      courtdate: 2.weeks.ago,
      court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE
    ),
    base_example.merge(
      description: 'with a court date more than three months before the court agreement',
      outcome: :address_court_agreement_breach,
      courtdate: 4.months.ago,
      court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE
    ),
    base_example.merge(
      description: 'with the last communication being an informal breach letter',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::INFORMAL_BREACH_LETTER_SENT,
      last_communication_date: 6.days.ago
    ),
    base_example.merge(
      description: 'with the last communication being a send letter one within 7 days',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
      last_communication_date: 6.days.ago
    ),
    base_example.merge(
      description: 'with the last communication being a send letter one, over 7 days ago',
      outcome: :send_informal_agreement_breach_letter,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
      last_communication_date: 8.days.ago
    ),
    base_example.merge(
      description: 'with the last communication being a send letter one, over 4 months ago',
      outcome: :send_informal_agreement_breach_letter,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
      last_communication_date: 4.months.ago
    ),
    base_example.merge(
      description: 'with the last communication being a send letter two within 7 days',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      last_communication_date: 6.days.ago
    ),
    base_example.merge(
      description: 'with the last communication being a send letter two, over 7 days ago',
      outcome: :send_informal_agreement_breach_letter,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2,
      last_communication_date: 8.days.ago
    )
  ]

  include_examples 'TenancyClassification', examples
end
