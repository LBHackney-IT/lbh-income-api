require 'rails_helper'

describe Hackney::Income::UniversalHousingAgreementGateway, universal: true do
  subject(:agreements) { described_class.for_tenancy(database_connection, tenancy_ref) }

  let(:database_connection) { Hackney::UniversalHousing::Client.connection }

  let(:tenancy_ref) { '012345/01' }

  context 'when provided a tenancy ref with a single agreement' do
    before do
      create_uh_agreement(agreement)
    end

    let(:agreement) {
      {
        tag_ref: tenancy_ref,
        arag_status: Hackney::Income::ACTIVE_ARREARS_AGREEMENT_STATUS,
        arag_startdate: DateTime.now.midnight - 7.days,
        arag_lastcheckbal: 1200.45,
        arag_lastcheckdate: DateTime.now.midnight,
        arag_lastexpectedbal: 1200.45,
        arag_breached: false,
        arag_startbal: 1230.45,
        arag_comment: 'Initial comment made when agreement was created',
        aragdet_amount: 1230.45,
        aragdet_comment: 'Subsequent comment made when agreement was updated',
        aragdet_startdate: DateTime.now.midnight,
        aragdet_frequency: 5
      }
    }

    it 'returns a single UH agreement in a dataset' do
      expect(subject.count).to eq(1)

      expect(subject[0][:start_date]).to eq(agreement[:aragdet_startdate])
      expect(subject[0][:status]).to eq(agreement[:arag_status])
      expect(subject[0][:last_check_balance]).to eq(agreement[:arag_lastcheckbal])
      expect(subject[0][:last_check_date]).to eq(agreement[:arag_lastcheckdate])
      expect(subject[0][:last_check_expected_balance]).to eq(agreement[:arag_lastexpectedbal])
      expect(subject[0][:breached]).to eq(agreement[:arag_breached])
      expect(subject[0][:starting_balance]).to eq(agreement[:arag_startbal])
      expect(subject[0][:comment]).to eq(agreement[:aragdet_comment])
      expect(subject[0][:amount]).to eq(agreement[:aragdet_amount])
      expect(subject[0][:frequency]).to eq(agreement[:aragdet_frequency])
    end
  end

  context 'when provided a tenancy ref with two agreements (separate arags)' do
    before do
      create_uh_agreement(agreement_one)
      create_uh_agreement(agreement_two)
    end

    let(:agreement_one) {
      {
        tag_ref: tenancy_ref,
        arag_startdate: nil,
        arag_status: Hackney::Income::ACTIVE_ARREARS_AGREEMENT_STATUS,
        aragdet_startdate: DateTime.now.midnight - 14.days,
        arag_breached: false,
        arag_startbal: 5000.00,
        arag_comment: nil,
        aragdet_comment: 'First agreement here',
        aragdet_amount: 100.40,
        aragdet_frequency: 5,
        arag_lastcheckbal: 1200.45,
        arag_lastcheckdate: DateTime.now.midnight,
        arag_lastexpectedbal: 1200.45
      }
    }

    let(:agreement_two) {
      {
        tag_ref: tenancy_ref,
        arag_startdate: nil,
        arag_status: Hackney::Income::ACTIVE_ARREARS_AGREEMENT_STATUS,
        aragdet_startdate: DateTime.now.midnight + 5.days,
        arag_breached: false,
        arag_startbal: 4500.00,
        arag_comment: nil,
        aragdet_comment: 'Replaces previous agreement to reduce payments',
        aragdet_amount: 50.20,
        aragdet_frequency: 5,
        arag_lastcheckbal: 1200.45,
        arag_lastcheckdate: DateTime.now.midnight,
        arag_lastexpectedbal: 1200.45
      }
    }

    it 'returns two UH agreements in an array' do
      expect(subject.count).to eq(2)

      first_agreement = subject[0]
      second_agreement = subject[1]

      expect(first_agreement[:start_date]).to eq(agreement_one[:aragdet_startdate])
      expect(first_agreement[:breached]).to eq(agreement_one[:arag_breached])
      expect(first_agreement[:starting_balance]).to eq(agreement_one[:arag_startbal])
      expect(first_agreement[:comment]).to eq(agreement_one[:aragdet_comment])
      expect(first_agreement[:amount]).to eq(agreement_one[:aragdet_amount])
      expect(first_agreement[:frequency]).to eq(agreement_one[:aragdet_frequency])

      expect(second_agreement[:start_date]).to eq(agreement_two[:aragdet_startdate])
      expect(second_agreement[:breached]).to eq(agreement_two[:arag_breached])
      expect(second_agreement[:starting_balance]).to eq(agreement_two[:arag_startbal])
      expect(second_agreement[:comment]).to eq(agreement_two[:aragdet_comment])
      expect(second_agreement[:amount]).to eq(agreement_two[:aragdet_amount])
      expect(second_agreement[:frequency]).to eq(agreement_two[:aragdet_frequency])
    end
  end

  context 'when provided a tenancy ref with two agreements (same arag)' do
    before do
      create_uh_agreement(agreement)

      update_uh_agreement(updated_agreement)
    end

    let(:agreement) {
      {
        tag_ref: tenancy_ref,
        arag_startdate: nil,
        arag_status: Hackney::Income::ACTIVE_ARREARS_AGREEMENT_STATUS,
        aragdet_startdate: DateTime.now.midnight - 14.days,
        arag_breached: false,
        arag_startbal: 5000.00,
        arag_comment: nil,
        aragdet_comment: 'First agreement here',
        aragdet_amount: 100.40,
        aragdet_frequency: 5,
        arag_lastcheckbal: 1200.45,
        arag_lastcheckdate: DateTime.now.midnight,
        arag_lastexpectedbal: 1200.45
      }
    }

    let(:updated_agreement) {
      {
        tag_ref: tenancy_ref,
        aragdet_comment: 'Replaces previous agreement to reduce payments',
        aragdet_amount: 50.20
      }
    }

    it 'returns two UH agreements in an array' do
      expect(subject.count).to eq(2)

      first_agreement = subject[0]
      second_agreement = subject[1]

      expect(first_agreement[:start_date]).to eq(agreement[:aragdet_startdate])
      expect(first_agreement[:breached]).to eq(agreement[:arag_breached])
      expect(first_agreement[:starting_balance]).to eq(agreement[:arag_startbal])
      expect(first_agreement[:comment]).to eq(agreement[:aragdet_comment])
      expect(first_agreement[:amount]).to eq(agreement[:aragdet_amount])
      expect(first_agreement[:frequency]).to eq(agreement[:aragdet_frequency])

      expect(second_agreement[:start_date]).to eq(agreement[:aragdet_startdate])
      expect(second_agreement[:breached]).to eq(agreement[:arag_breached])
      expect(second_agreement[:starting_balance]).to eq(agreement[:arag_startbal])
      expect(second_agreement[:frequency]).to eq(agreement[:aragdet_frequency])
      expect(second_agreement[:comment]).to eq(updated_agreement[:aragdet_comment])
      expect(second_agreement[:amount]).to eq(updated_agreement[:aragdet_amount])
    end

    it 'Reports that the first aragdet agreement row has been cancelled, as it is replaced by the latter' do
      first_agreement = subject[0]
      second_agreement = subject[1]

      expect(first_agreement[:status]).to eq(Hackney::Income::CANCELLED_ARREARS_AGREEMENT_STATUS)
      expect(second_agreement[:status]).to eq(Hackney::Income::ACTIVE_ARREARS_AGREEMENT_STATUS)
    end
  end

  context 'when provided a tenancy ref with two agreements first one is active (two aragdets), second is cancelled' do
    before do
      create_uh_agreement(agreement_one)
      update_uh_agreement(agreement_one_updated)

      create_uh_agreement(agreement_two)
    end

    let(:agreement_one) {
      {
        tag_ref: tenancy_ref,
        arag_startdate: nil,
        arag_status: Hackney::Income::ACTIVE_ARREARS_AGREEMENT_STATUS,
        aragdet_startdate: DateTime.now.midnight - 14.days,
        arag_breached: false,
        arag_startbal: 5000.00,
        arag_comment: nil,
        aragdet_comment: 'First agreement here',
        aragdet_amount: 100.40,
        aragdet_frequency: 5,
        arag_lastcheckbal: 1200.45,
        arag_lastcheckdate: DateTime.now.midnight,
        arag_lastexpectedbal: 1200.45
      }
    }

    let(:agreement_one_updated) {
      {
        tag_ref: tenancy_ref,
        aragdet_comment: 'Replaces previous agreement to reduce payments',
        aragdet_amount: 50.20
      }
    }

    let(:agreement_two) {
      {
        tag_ref: tenancy_ref,
        arag_startdate: nil,
        arag_status: Hackney::Income::CANCELLED_ARREARS_AGREEMENT_STATUS,
        aragdet_startdate: DateTime.now.midnight - 14.days,
        arag_breached: false,
        arag_startbal: 5000.00,
        arag_comment: nil,
        aragdet_comment: 'Second cancelled agreement here',
        aragdet_amount: 100.40,
        aragdet_frequency: 5,
        arag_lastcheckbal: 1200.45,
        arag_lastcheckdate: DateTime.now.midnight,
        arag_lastexpectedbal: 1200.45
      }
    }

    it 'returns three UH agreements in an array' do
      expect(subject.count).to eq(3)
    end

    it 'correctly reflects the status of the three agreements' do
      expect(subject[0][:status]).to eq(Hackney::Income::CANCELLED_ARREARS_AGREEMENT_STATUS)
      expect(subject[1][:status]).to eq(Hackney::Income::ACTIVE_ARREARS_AGREEMENT_STATUS)
      expect(subject[2][:status]).to eq(Hackney::Income::CANCELLED_ARREARS_AGREEMENT_STATUS)
    end
  end
end
