require 'rails_helper'

describe 'Send Court Agreement Breach Letter Rule', type: :feature do
  send_court_agreement_breach_letter_condition_matrix = [
    {
      # where all conditions are set, with Adjourned on Terms outcome code
      outcome: :send_court_agreement_breach_letter,
      active_agreement: false,
      court_outcome: Hackney::Tenancy::ActionCodes::ADJOURNED_ON_TERMS_COURT_OUTCOME,
      courtdate: 8.days.ago,
      latest_active_agreement_date: 7.days.ago,
      balance: 5,
      expected_balance: 10,
      breach_agreement_date: 4.days.ago,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 1
    },
    {
      # where all conditions are set, with Postponed Possession outcome code
      outcome: :send_court_agreement_breach_letter,
      active_agreement: false,
      court_outcome: Hackney::Tenancy::ActionCodes::POSTPONED_POSSESSIOON_COURT_OUTCOME,
      courtdate: 8.days.ago,
      latest_active_agreement_date: 7.days.ago,
      balance: 5,
      expected_balance: 10,
      breach_agreement_date: 4.days.ago,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 1
    },
    {
      # where all conditions are set, with Suspended Possession outcome code
      outcome: :send_court_agreement_breach_letter,
      active_agreement: false,
      court_outcome: Hackney::Tenancy::ActionCodes::SUSPENDED_POSSESSION_COURT_OUTCOME,
      courtdate: 8.days.ago,
      latest_active_agreement_date: 7.days.ago,
      balance: 5,
      expected_balance: 10,
      breach_agreement_date: 4.days.ago,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 1
    },
    {
      # no court outcome
      outcome: :update_court_outcome_action,
      active_agreement: false,
      court_outcome: '',
      courtdate: 8.days.ago,
      latest_active_agreement_date: 7.days.ago,
      breach_agreement_date: 3.days.ago,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 1

    },
    {
      # courtdate after active agreement date
      outcome: :no_action,
      active_agreement: false,
      court_outcome: 'AGR',
      courtdate: Date.today,
      latest_active_agreement_date: 7.days.ago,
      breach_agreement_date: 3.days.ago,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 1
    },
    {
      # has not been in breach for at least 3 days
      outcome: :no_action,
      active_agreement: false,
      court_outcome: 'AGR',
      courtdate: 8.days.ago,
      latest_active_agreement_date: 7.days.ago,
      breach_agreement_date: 1.day.ago,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 1
    },
    {
      # there is an active agreement
      outcome: :no_action,
      active_agreement: true,
      court_outcome: 'AGR',
      courtdate: 8.days.ago,
      latest_active_agreement_date: 7.days.ago,
      breach_agreement_date: 1.day.ago,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 1
    },
    {
      # there is no broken agreements
      outcome: :no_action,
      active_agreement: false,
      court_outcome: 'AGR',
      courtdate: 8.days.ago,
      latest_active_agreement_date: 7.days.ago,
      breach_agreement_date: 1.day.ago,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 0
    },
    {
      # where the balance is less then expected balance
      outcome: :no_action,
      active_agreement: false,
      court_outcome: 'AGR',
      courtdate: 8.days.ago,
      latest_active_agreement_date: 7.days.ago,
      balance: 10,
      expected_balance: 10,
      breach_agreement_date: 4.days.ago,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 1
    },
    {
      # when the latest agctive agreement date does not exist
      outcome: :no_action,
      active_agreement: false,
      court_outcome: 'AGR',
      courtdate: 8.days.ago,
      latest_active_agreement_date: nil,
      balance: 1234,
      expected_balance: 10,
      breach_agreement_date: 4.days.ago,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 1
    },
    {
      # where there is no breach agreement date
      outcome: :send_court_agreement_breach_letter,
      active_agreement: false,
      court_outcome: Hackney::Tenancy::ActionCodes::SUSPENDED_POSSESSION_COURT_OUTCOME,
      courtdate: 8.days.ago,
      latest_active_agreement_date: 7.days.ago,
      balance: 5,
      expected_balance: 10,
      breach_agreement_date: nil,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 1
    }
    # {
    #   #last communicated action was not send court warning letter
    #   outcome: :no_action,
    #   active_agreement: true,
    #   court_outcome: 'AGR',
    #   courtdate: 8.days.ago,
    #   latest_active_agreement_date: 7.days.ago,
    #   breach_agreement_date: 1.day.ago,
    #   last_communication_action: 'ANYTHING',
    #   number_of_broken_agreements: 1

    # }

  ]

  it_behaves_like 'TenancyClassification', send_court_agreement_breach_letter_condition_matrix
end
