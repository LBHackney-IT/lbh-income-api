require 'rails_helper'

describe 'Send Court Agreement Breach Letter Rule', type: :feature do
  send_court_agreement_breach_letter_condition_matrix = [
    {
      # where all conditions are set so an Breach
      outcome: :send_court_agreement_breach_letter,
      active_agreement: false,
      court_outcome: 'AGR',
      courtdate: 8.days.ago,
      latest_active_agreement_date: 7.days.ago,
      breach_agreement_date: 4.days.ago,
      last_communication_action: Hackney::Tenancy::ActionCodes::COURT_WARNING_LETTER_SENT,
      last_communication_date: 1.month.ago,
      number_of_broken_agreements: 1
    },
    {
      # no court outcome
      outcome: :no_action,
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
