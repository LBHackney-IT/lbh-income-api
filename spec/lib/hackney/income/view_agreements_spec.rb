require 'rails_helper'

describe Hackney::Income::ViewAgreements do
  subject { described_class.execute(tenancy_ref: tenancy_ref) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }

  it 'returns all agreements with the given tenancy_ref' do
    Hackney::Income::Models::Agreement.create!(tenancy_ref: tenancy_ref)

    response = subject

    expect(response[:agreements].count).to eq(1)
    expect(response[:agreements].first[:tenancyRef]).to eq(tenancy_ref)
  end
end
