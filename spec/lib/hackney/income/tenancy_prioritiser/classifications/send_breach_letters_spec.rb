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
    base_example.merge(
      description: 'with a court date after the agreement',
      outcome: :send_informal_agreement_breach_letter,
      courtdate: 1.day.ago,
      court_outcome: 'something'
    ),
    base_example.merge(
      description: 'with a court date before the agreement',
      outcome: :send_court_agreement_breach_letter,
      courtdate: 2.weeks.ago,
      court_outcome: 'something'
    ),
    base_example.merge(
      description: 'with a court date more than three months before the agreement',
      outcome: :send_informal_agreement_breach_letter,
      courtdate: 4.months.ago,
      court_outcome: 'something'
    )
  ]

  include_examples 'TenancyClassification', examples
end
