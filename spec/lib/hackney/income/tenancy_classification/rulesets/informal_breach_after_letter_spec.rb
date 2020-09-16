require 'rails_helper'

describe 'Informal Breach after letter' do
  base_example = {
    outcome: :informal_breached_after_letter,
    most_recent_agreement: {
      start_date: 2.week.ago,
      breached: true
    },
    last_communication_action: Hackney::Tenancy::ActionCodes::INFORMAL_BREACH_LETTER_SENT,
    last_communication_date: 8.days.ago
  }

  examples = [
    base_example,
    base_example.deep_merge(
      description: 'with an unbreached agreement',
      outcome: :no_action,
      most_recent_agreement: { breached: false }
    ),
    base_example.deep_merge(
      description: 'with the informal breach letter being sent within 7 days',
      outcome: :no_action,
      last_communication_date: 6.days.ago
    ),
    base_example.deep_merge(
      description: 'with a letter one sent last',
      outcome: :send_informal_agreement_breach_letter,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1
    ),
    base_example.deep_merge(
      description: 'with a letter two sent last',
      outcome: :send_informal_agreement_breach_letter,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2
    ),
    base_example.deep_merge(
      description: 'with a NOSP served',
      outcome: :no_action,
      nosp_served_date: 8.days.ago
    )
  ]

  include_examples 'TenancyClassification', examples
end
