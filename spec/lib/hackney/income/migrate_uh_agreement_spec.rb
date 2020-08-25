require 'rails_helper'

describe Hackney::Income::MigrateUhAgreement, universal: true do
  subject do
    described_class.new(
      view_agreements: view_agreements,
      view_court_cases: view_court_cases,
      create_informal_agreement: create_informal_agreement,
      create_formal_agreement: create_formal_agreement,
      create_agreement_migration: create_agreement_migration
    )
  end

  let(:tenancy_ref) { '12345/01' }

  let(:view_agreements) { double(Hackney::Income::ViewAgreements) }
  let(:view_court_cases) { double(Hackney::Income::ViewCourtCases) }
  let(:create_informal_agreement) { double(Hackney::Income::CreateInformalAgreement) }
  let(:create_formal_agreement) { double(Hackney::Income::CreateFormalAgreement) }
  let(:create_agreement_migration) { double(Hackney::Income::CreateAgreementMigration) }

  let(:criteria) { Stubs::StubCriteria.new(criteria_attributes) }
  let(:existing_court_cases) { [] }

  before do
    allow(view_court_cases).to receive(:execute).and_return(existing_court_cases)

    expect(Hackney::Income::UniversalHousingAgreementGateway)
      .to receive(:for_tenancy).and_return(uh_agreements)
  end

  context 'when there are no UH agreements' do
    let(:uh_agreements) { [] }

    it 'does not call anything' do
      expect(view_agreements).not_to receive(:execute)
      expect(view_court_cases).not_to receive(:execute)
      expect(create_informal_agreement).not_to receive(:execute)
      expect(create_formal_agreement).not_to receive(:execute)
      expect(create_agreement_migration).not_to receive(:execute)

      subject.migrate(tenancy_ref: tenancy_ref)
    end
  end

  context 'when there is a UH agreement and MA agreements' do
    let(:new_agreement) { create(:agreement) }

    let(:amount) { 3.55 }
    let(:uh_id) { 110_639_718 }
    let(:starting_balance) { 273.52 }

    let(:uh_agreements) {
      [{
        start_date: '2012-12-24',
        status: '400       ',
        breached: true,
        last_check_balance: 154.0,
        last_check_date: '2013-11-30',
        last_check_expected_balance: 99.57,
        starting_balance: starting_balance,
        comment: ' ',
        amount: amount,
        frequency: 1,
        uh_id: uh_id
      }]
    }

    before do
      expect(view_agreements).to receive(:execute).and_return([new_agreement])
    end

    it 'nothing get\'s migrated' do
      expect(view_court_cases).not_to receive(:execute)
      expect(create_informal_agreement).not_to receive(:execute)
      expect(create_formal_agreement).not_to receive(:execute)
      expect(create_agreement_migration).not_to receive(:execute)

      subject.migrate(tenancy_ref: tenancy_ref)
    end
  end

  context 'when there is a UH agreement but no MA agreements' do
    let(:new_agreement) { create(:agreement) }

    let(:amount) { 3.55 }
    let(:uh_id) { 110_639_718 }
    let(:starting_balance) { 273.52 }

    let(:uh_agreements) {
      [{
        start_date: '2012-12-24',
        status: '400       ',
        breached: true,
        last_check_balance: 154.0,
        last_check_date: '2013-11-30',
        last_check_expected_balance: 99.57,
        starting_balance: starting_balance,
        comment: ' ',
        amount: amount,
        frequency: 1,
        uh_id: uh_id
      }]
    }

    before do
      expect(view_agreements).to receive(:execute).and_return([])
      expect(view_court_cases).to receive(:execute).and_return([])
    end

    it 'migrates an informal agreement' do
      expect(create_informal_agreement).to receive(:execute).with(
        new_agreement_params: {
          agreement_type: :informal,
          amount: amount,
          court_case_id: nil,
          created_by: 'Managed Arrears migration from UH',
          frequency: 0,
          notes: ' ',
          start_date: '2012-12-24',
          starting_balance: starting_balance,
          tenancy_ref: tenancy_ref
        }
      ).and_return(new_agreement)

      expect(create_formal_agreement).not_to receive(:execute)

      expect(create_agreement_migration).to receive(:execute).with(
        agreement_migration_params: {
          agreement_id: new_agreement.id,
          legacy_id: uh_id
        }
      )

      subject.migrate(tenancy_ref: tenancy_ref)
    end
  end

  context 'when there is a UH agreement, no MA agreements and a court case' do
    let(:new_agreement) { create(:agreement) }
    let(:court_case) { create(:court_case) }

    let(:amount) { 3.55 }
    let(:uh_id) { 110_639_718 }
    let(:starting_balance) { 273.52 }

    let(:uh_agreements) {
      [{
        start_date: '2012-12-24',
        status: '400       ',
        breached: true,
        last_check_balance: 154.0,
        last_check_date: '2013-11-30',
        last_check_expected_balance: 99.57,
        starting_balance: starting_balance,
        comment: ' ',
        amount: amount,
        frequency: 4,
        uh_id: uh_id
      }]
    }

    before do
      expect(view_agreements).to receive(:execute).and_return([])
      expect(view_court_cases).to receive(:execute).and_return([court_case])
    end

    it 'migrates an informal agreement' do
      expect(create_formal_agreement).to receive(:execute).with(
        new_agreement_params: {
          agreement_type: :formal,
          amount: amount,
          court_case_id: court_case.id,
          created_by: 'Managed Arrears migration from UH',
          frequency: 3,
          notes: ' ',
          start_date: '2012-12-24',
          starting_balance: starting_balance,
          tenancy_ref: tenancy_ref
        }
      ).and_return(new_agreement)

      expect(create_informal_agreement).not_to receive(:execute)

      expect(create_agreement_migration).to receive(:execute).with(
        agreement_migration_params: {
          agreement_id: new_agreement.id,
          legacy_id: uh_id
        }
      )

      subject.migrate(tenancy_ref: tenancy_ref)
    end
  end
end
