require 'rails_helper'

describe 'Apply for Outright Possession Warrant Rule examples' do
  base_example = {
    outcome: :apply_for_outright_possession_warrant,
    active_agreement: false,
    courtdate: 1.month.ago,
    court_outcome: 'OPD'
  }
  examples = [
    base_example,
    base_example.merge(
      desription: 'when the court outcome is outright possession forthright',
      court_outcome: 'OPF'
    ),
    base_example.merge(
      desription: 'when the court date is in the future',
      outcome: :no_action,
      active_agreement: false,
      courtdate: 1.week.from_now,
      court_outcome: 'OUT'
    ),
    base_example.merge(
      desription: 'when the court date was more than 3 months ago',
      active_agreement: false,
      outcome: :no_action,
      courtdate: 4.month.ago,
      court_outcome: 'OUT'
    ),
    base_example.merge(
      desription: 'when the court date does not exist',
      active_agreement: false,
      outcome: :no_action,
      courtdate: nil,
      court_outcome: 'OUT'
    ),
    base_example.merge(
      desription: 'when there is an active agreement in place after outright possession order',
      active_agreement: true,
      outcome: :no_action,
      courtdate: 1.month.ago,
      court_outcome: 'OUT'
    ),
    base_example.merge(
      description: 'when they have already applied for a warrent of possession',
      outcome: :no_action,
      last_communication_action: Hackney::Tenancy::ActionCodes::WARRANT_OF_POSSESSION
    )
  ]
  it_behaves_like 'TenancyClassification', examples
end
