require 'rails_helper'
base_example = {
  skip_v1_test: true
}
describe 'Check Data examples' do
  examples = [
    base_example.merge(
      desription: 'When there is an active court warrant, without an agreement, and not paused',
      outcome: :check_data,
      active_agreement: false,
      courtdate: 1.week.ago,
      court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY
    ), base_example.merge(
      desription: 'No action when there is no court warrant',
      outcome: :no_action,
      active_agreement: false,
      courtdate: nil
    ), base_example.merge(
      desription: 'No action when there is an active court warrant, without an agreement, but is paused',
      outcome: :no_action,
      is_paused_until: 1.day.from_now.to_date,
      active_agreement: false,
      courtdate: 1.week.ago,
      court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY
    ), base_example.merge(
      desription: 'No action when there is an old court warrant, without an agreement, and not paused',
      outcome: :no_action,
      active_agreement: false,
      courtdate: 11.years.ago,
      court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY
    ), base_example.merge(
      desription: 'No action when there is an not an active court warrant',
      outcome: :no_action,
      courtdate: nil
    ),
    base_example.merge(
      description: 'Check Data when case has court outcome but no court date',
      outcome: :check_data,
      courtdate: nil,
      court_outcome: Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY
    )
  ]
  it_behaves_like 'TenancyClassification', examples
end
