require 'rails_helper'

describe Hackney::Income::UniversalHousingAgreementGateway, universal: true do
  subject(:criteria) { described_class.new(universal_housing_client).for_tenancy(tenancy_ref: tenancy_ref) }

  let(:universal_housing_client) { Hackney::UniversalHousing::Client.connection }

  context 'when provided a tenancy ref with a single agreement' do
    before do
      create_uh_agreement(
        tag_ref: tenancy_ref,
        arag_startdate: startdate,
        arag_breached: breached,
        arag_startbal: startbal,
        arag_comment: comment,
        aragdet_amount: amount
      )
    end

    let(:tenancy_ref) { '012345/01' }
    let(:startdate) { DateTime.now.midnight - 7.days }
    let(:breached) { false }
    let(:startbal) { 1230.45 }
    let(:comment) { Faker::ChuckNorris.fact }
    let(:amount) { 10.42 }

    it 'returns a single UH agreement in a dataset' do
      expect(subject.count).to eq(1)
      agreement = subject[0]
      expect(agreement[:start_date]).to eq(startdate)
      expect(agreement[:breached]).to eq(breached)
      expect(agreement[:starting_balance]).to eq(startbal)
      expect(agreement[:comment]).to eq(comment)
      expect(agreement[:amount]).to eq(amount)
    end
  end
end
