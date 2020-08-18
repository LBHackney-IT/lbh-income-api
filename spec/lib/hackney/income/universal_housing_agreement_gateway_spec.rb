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
        aragdet_amount: amount,
        aragdet_comment: aragdet_comment,
        aragdet_startdate: aragdet_startdate,
        aragdet_frequency: frequency
      )
    end

    let(:tenancy_ref) { '012345/01' }
    let(:startdate) { DateTime.now.midnight - 7.days }
    let(:aragdet_startdate) { DateTime.now.midnight + 5.days }
    let(:breached) { false }
    let(:startbal) { 1230.45 }
    let(:comment) { 'Initial comment made when agreement was created' }
    let(:aragdet_comment) { 'Subsequent comment made when agreement was updated' }
    let(:amount) { 10.42 }
    let(:frequency) { 5 }

    it 'returns a single UH agreement in a dataset' do
      expect(subject.count).to eq(1)
      agreement = subject[0]
      expect(agreement[:start_date]).to eq(aragdet_startdate)
      expect(agreement[:breached]).to eq(breached)
      expect(agreement[:starting_balance]).to eq(startbal)
      expect(agreement[:comment]).to eq(aragdet_comment)
      expect(agreement[:amount]).to eq(amount)
      expect(agreement[:frequency]).to eq(frequency)
    end
  end

  context 'when provided a tenancy ref with two agreements (separate arags)' do
    before do
      create_uh_agreement(
        agreement_one.symbolize_keys
      )

      create_uh_agreement(
        agreement_two.symbolize_keys
      )
    end

    let(:tenancy_ref) { '012345/01' }

    let(:agreement_one) {
      {
        tag_ref: tenancy_ref,
        arag_startdate: nil,
        aragdet_startdate: DateTime.now.midnight - 14.days,
        arag_breached: false,
        arag_startbal: 5000.00,
        arag_comment: nil,
        aragdet_comment: 'First agreement here',
        aragdet_amount: 100.40,
        aragdet_frequency: 5
      }
    }

    let(:agreement_two) {
      {
        tag_ref: tenancy_ref,
        arag_startdate: nil,
        aragdet_startdate: DateTime.now.midnight + 5.days,
        arag_breached: false,
        arag_startbal: 4500.00,
        arag_comment: nil,
        aragdet_comment: 'Replaces previous agreement to reduce payments',
        aragdet_amount: 50.20,
        aragdet_frequency: 5
      }
    }

    it 'returns two UH agreements in an array' do
      expect(subject.count).to eq(2)
      agreement = subject[0]
      expect(agreement[:start_date]).to eq(agreement_one[:aragdet_startdate])
      expect(agreement[:breached]).to eq(agreement_one[:arag_breached])
      expect(agreement[:starting_balance]).to eq(agreement_one[:arag_startbal])
      expect(agreement[:comment]).to eq(agreement_one[:aragdet_comment])
      expect(agreement[:amount]).to eq(agreement_one[:aragdet_amount])
      expect(agreement[:frequency]).to eq(agreement_one[:aragdet_frequency])

      agreement = subject[1]
      expect(agreement[:start_date]).to eq(agreement_two[:aragdet_startdate])
      expect(agreement[:breached]).to eq(agreement_two[:arag_breached])
      expect(agreement[:starting_balance]).to eq(agreement_two[:arag_startbal])
      expect(agreement[:comment]).to eq(agreement_two[:aragdet_comment])
      expect(agreement[:amount]).to eq(agreement_two[:aragdet_amount])
      expect(agreement[:frequency]).to eq(agreement_two[:aragdet_frequency])
    end
  end

  context 'when provided a tenancy ref with two agreements (same arag)' do
    before do
      create_uh_agreement(
        agreement_one.symbolize_keys
      )

      update_uh_agreement(
        tag_ref: tenancy_ref,
        aragdet_comment: updated_agreement[:aragdet_comment],
        aragdet_amount: updated_agreement[:aragdet_amount]
      )
    end

    let(:tenancy_ref) { '012345/01' }

    let(:agreement_one) {
      {
        tag_ref: tenancy_ref,
        arag_startdate: nil,
        aragdet_startdate: DateTime.now.midnight - 14.days,
        arag_breached: false,
        arag_startbal: 5000.00,
        arag_comment: nil,
        aragdet_comment: 'First agreement here',
        aragdet_amount: 100.40,
        aragdet_frequency: 5
      }
    }

    let(:updated_agreement) {
      {
        aragdet_comment: 'Replaces previous agreement to reduce payments',
        aragdet_amount: 50.20
      }
    }

    it 'returns two UH agreements in an array' do
      expect(subject.count).to eq(2)
      agreement = subject[0]
      expect(agreement[:start_date]).to eq(agreement_one[:aragdet_startdate])
      expect(agreement[:breached]).to eq(agreement_one[:arag_breached])
      expect(agreement[:starting_balance]).to eq(agreement_one[:arag_startbal])
      expect(agreement[:comment]).to eq(agreement_one[:aragdet_comment])
      expect(agreement[:amount]).to eq(agreement_one[:aragdet_amount])
      expect(agreement[:frequency]).to eq(agreement_one[:aragdet_frequency])

      agreement = subject[1]
      expect(agreement[:start_date]).to eq(agreement_one[:aragdet_startdate])
      expect(agreement[:breached]).to eq(agreement_one[:arag_breached])
      expect(agreement[:starting_balance]).to eq(agreement_one[:arag_startbal])
      expect(agreement[:frequency]).to eq(agreement_one[:aragdet_frequency])
      expect(agreement[:comment]).to eq(updated_agreement[:aragdet_comment])
      expect(agreement[:amount]).to eq(updated_agreement[:aragdet_amount])
    end
  end
end
