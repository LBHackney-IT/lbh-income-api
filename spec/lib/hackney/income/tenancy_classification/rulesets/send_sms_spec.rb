require 'rails_helper'

describe 'Send First SMS Rule examples' do
  base_example = {
    outcome: :send_first_SMS,
    balance: 5
  }
  examples = [
    base_example,
    base_example.merge(
      description: 'when there is an active agreement',
      outcome: :no_action,
      most_recent_agreement: {
        start_date: 1.month.ago,
        breached: false
      }
    ),
    base_example.merge(
      description: 'when the balance is less than £5',
      outcome: :no_action,
      balance: 1
    ),
    base_example.merge(
      description: 'when there is a nosp',
      outcome: :no_action,
      nosp_served_date: 1.week.ago
    ),
    base_example.merge(
      description: 'when there is a court date in the past',
      outcome: :no_action,
      courtdate: 1.week.ago,
      court_outcome: 'TEST'
    ),
    base_example.merge(
      description: 'when there is a court date in the future',
      outcome: :no_action,
      courtdate: 1.week.from_now
    ),
    base_example.merge(
      description: 'when there is an eviction date in the future',
      outcome: :no_action,
      eviction_date: 1.week.from_now
    ),
    base_example.merge(
      description: 'when there is an eviction date in the past',
      outcome: :no_action,
      eviction_date: 1.week.ago
    ),
    base_example.merge(
      description: 'when the last comm action is Automated SMS code and within 7 days',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::AUTOMATED_SMS_ACTION_CODE,
      last_communication_date: 7.days.ago
    ),
    base_example.merge(
      description: 'when the last comm action is Automated SMS code and was over 7 days ago',
      outcome: :send_first_SMS,
      last_communication_action: Hackney::Tenancy::ActionCodes::AUTOMATED_SMS_ACTION_CODE,
      last_communication_date: 8.days.ago
    ),
    base_example.merge(
      description: 'when the last comm action is Manual SMS code and within 7 days',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::MANUAL_SMS_ACTION_CODE,
      last_communication_date: 7.days.ago
    ),
    base_example.merge(
      description: 'when the last comm action is Manual SMS code and was over 7 days ago',
      outcome: :send_first_SMS,
      last_communication_action: Hackney::Tenancy::ActionCodes::MANUAL_SMS_ACTION_CODE,
      last_communication_date: 8.days.ago
    ),
    base_example.merge(
      description: 'when the last comm action is Manual Green SMS code and within 7 days',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::MANUAL_GREEN_SMS_ACTION_CODE,
      last_communication_date: 7.days.ago
    ),
    base_example.merge(
      description: 'when the last comm action is Manual Green SMS code and was over 7 days ago',
      outcome: :send_first_SMS,
      last_communication_action: Hackney::Tenancy::ActionCodes::MANUAL_GREEN_SMS_ACTION_CODE,
      last_communication_date: 8.days.ago
    ),
    base_example.merge(
      description: 'when the last comm action is Manual Amber SMS code and within 7 days',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::MANUAL_AMBER_SMS_ACTION_CODE,
      last_communication_date: 7.days.ago
    ),
    base_example.merge(
      description: 'when the last comm action is Manual Amber SMS code and was over 7 days ago',
      outcome: :send_first_SMS,
      last_communication_action: Hackney::Tenancy::ActionCodes::MANUAL_AMBER_SMS_ACTION_CODE,
      last_communication_date: 8.days.ago
    ),
    base_example.merge(
      description: 'when the last comm action is generic SMS code and within 7 days',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::TEXT_MESSAGE_SENT,
      last_communication_date: 7.days.ago
    ),
    base_example.merge(
      description: 'when the last comm action is generic SMS code and was over 7 days ago',
      outcome: :send_first_SMS,
      last_communication_action: Hackney::Tenancy::ActionCodes::TEXT_MESSAGE_SENT,
      last_communication_date: 8.days.ago
    ),
    base_example.merge(
      description: 'when the case is paused',
      outcome: :no_action,
      is_paused_until: 1.week.from_now
    ),
    base_example.merge(
      description: 'when the last comm action is send letter one within 3 months',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
      last_communication_date: 1.months.ago
    ),
    base_example.merge(
      description: 'when the last comm action is send letter one over 3 months ago',
      outcome: :send_first_SMS,
      last_communication_action: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1,
      last_communication_date: 4.months.ago
    )
  ]

  it_behaves_like 'TenancyClassification', examples
end
