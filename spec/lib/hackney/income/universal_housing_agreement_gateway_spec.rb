require 'rails_helper'

describe Hackney::Income::UniversalHousingAgreementGateway, universal: true do
  subject(:criteria) { described_class.new(universal_housing_client).for_tenancy(tenancy_ref: tenancy_ref) }

  let(:universal_housing_client) { Hackney::UniversalHousing::Client.connection }

  context 'when provided a tenancy ref with a single agreement' do
    before do
      create_uh_agreement(
        tenancy_ref: tenancy_ref,
        startdate: startdate
      )
    end

    let(:tenancy_ref) { '012345/01' }
    let(:startdate) { DateTime.now.midnight - 7.days }

    it 'returns a single UH agreement in a dataset' do
      expect(subject.count).to eq(1)
      expect(subject[0][:startdate]).to eq(startdate)
    end
  end
end
