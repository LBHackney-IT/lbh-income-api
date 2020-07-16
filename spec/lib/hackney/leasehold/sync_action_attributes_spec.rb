require 'rails_helper'

describe Hackney::Leasehold::SyncActionAttributes do
  subject {
    described_class.new(
      universal_housing_gateway: universal_housing_gateway,
      stored_action_gateway: stored_action_gateway
    )
  }

  let(:universal_housing_gateway) {
    double(Hackney::Leasehold::UniversalHousingGateway)
  }

  let(:stored_action_gateway) {
    double(Hackney::Leasehold::StoredActionGateway)
  }

  let(:case_attributes) { Stubs::StubLeaseholdCriteria.new }

  let(:tenancy_ref) { Faker::Lorem.characters(number: 8) }

  it 'fetches case attributes form UH and saves it' do
    expect(universal_housing_gateway).to receive(:fetch).with(tenancy_ref).and_return(case_attributes)

    expect(stored_action_gateway).to receive(:store_action).with(
      tenancy_ref: tenancy_ref, criteria: case_attributes
    )

    subject.execute(
      tenancy_ref: tenancy_ref
    )
  end
end
