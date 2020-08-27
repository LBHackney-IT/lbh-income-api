require 'rails_helper'

describe Hackney::Income::MigrateUhAgreement, universal: true do
  subject do
    described_class.new(
      view_agreements: view_agreements,
      view_court_cases: view_court_cases,
      create_agreement: create_agreement,
      create_agreement_migration: create_agreement_migration
    )
  end

  let(:tenancy_ref) { '12345/01' }

  let(:view_agreements) { double(Hackney::Income::ViewAgreements) }
  let(:view_court_cases) { double(Hackney::Income::ViewCourtCases) }
  let(:create_agreement) { double(Hackney::Income::CreateAgreement) }
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
      expect(create_agreement).not_to receive(:execute)
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
      expect(create_agreement).not_to receive(:create_agreement)
      expect(create_agreement).not_to receive(:execute)
      expect(create_agreement_migration).not_to receive(:execute)

      subject.migrate(tenancy_ref: tenancy_ref)
    end
  end

  context 'when there is a UH agreement but no MA agreements' do
    let(:new_agreement) { create(:agreement) }

    let(:amount) { 3.55 }
    let(:uh_id) { 110_639_718 }
    let(:starting_balance) { 273.52 }
    let(:last_check_expected_balance) { 99.57 }
    let(:last_check_balance) { 154.0 }
    let(:start_date) { '2012-12-24' }
    let(:comment) { 'Something' }

    let(:uh_agreements) {
      [{
        start_date: start_date,
        status: '400       ',
        breached: true,
        last_check_balance: last_check_balance,
        last_check_date: '2013-11-30',
        last_check_expected_balance: last_check_expected_balance,
        starting_balance: starting_balance,
        comment: comment,
        amount: amount,
        frequency: 4,
        uh_id: uh_id
      }]
    }

    before do
      expect(view_agreements).to receive(:execute).and_return([])
      expect(view_court_cases).to receive(:execute).and_return([])
    end

    it 'migrates an informal agreement' do
      expect(create_agreement).to receive(:create_agreement).with(
        {
          tenancy_ref: tenancy_ref,
          agreement_type: :informal,
          starting_balance: starting_balance,
          amount: amount,
          start_date: start_date,
          frequency: 3,
          created_by: 'Managed Arrears migration from UH',
          notes: comment,
          court_case_id: nil
        },
        starting_balance: starting_balance,
        expected_balance: last_check_expected_balance,
        checked_balance: last_check_balance,
        description: 'Managed Arrears migration from UH',
        agreement_state: :cancelled
      ).and_return(new_agreement)

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
    let(:last_check_expected_balance) { 99.57 }
    let(:last_check_balance) { 154.0 }
    let(:start_date) { '2012-12-24' }
    let(:comment) { 'Something' }

    let(:uh_agreements) {
      [{
        start_date: start_date,
        status: '400       ',
        breached: true,
        last_check_balance: last_check_balance,
        last_check_date: '2013-11-30',
        last_check_expected_balance: last_check_expected_balance,
        starting_balance: starting_balance,
        comment: comment,
        amount: amount,
        frequency: 4,
        uh_id: uh_id
      }]
    }

    before do
      expect(view_agreements).to receive(:execute).and_return([])
      expect(view_court_cases).to receive(:execute).and_return([court_case])
    end

    it 'migrates a formal agreement' do
      expect(create_agreement).to receive(:create_agreement).with(
        {
          tenancy_ref: tenancy_ref,
          agreement_type: :formal,
          starting_balance: starting_balance,
          amount: amount,
          start_date: start_date,
          frequency: 3,
          created_by: 'Managed Arrears migration from UH',
          notes: comment,
          court_case_id: court_case.id
        },
        starting_balance: starting_balance,
        expected_balance: last_check_expected_balance,
        checked_balance: last_check_balance,
        description: 'Managed Arrears migration from UH',
        agreement_state: :cancelled
      ).and_return(new_agreement)

      expect(create_agreement).not_to receive(:execute)

      expect(create_agreement_migration).to receive(:execute).with(
        agreement_migration_params: {
          agreement_id: new_agreement.id,
          legacy_id: uh_id
        }
      )

      subject.migrate(tenancy_ref: tenancy_ref)
    end
  end

  context 'when there are 2 UH agreements, no MA agreements and a court case' do
    let(:formal_agreement) { create(:agreement) }
    let(:informal_agreement) { create(:agreement) }
    let(:court_case) { create(:court_case) }

    let(:formal_amount) { 32.55 }
    let(:formal_uh_id) { 110_639_730 }
    let(:formal_starting_balance) { 2743.52 }
    let(:formal_last_check_expected_balance) { 99.57 }
    let(:formal_last_check_balance) { 154.0 }
    let(:formal_start_date) { '2012-12-24' }
    let(:formal_comment) { 'Something' }

    let(:informal_amount) { 3.55 }
    let(:informal_uh_id) { 110_639_712 }
    let(:informal_starting_balance) { 273.52 }
    let(:informal_last_check_expected_balance) { 9.57 }
    let(:informal_last_check_balance) { 184.0 }
    let(:informal_start_date) { '2014-12-24' }
    let(:informal_comment) { 'Something else' }

    let(:uh_agreements) {
      [{
        start_date: informal_start_date,
        status: '500       ',
        breached: true,
        last_check_balance: informal_last_check_balance,
        last_check_date: '2013-11-30',
        last_check_expected_balance: informal_last_check_expected_balance,
        starting_balance: informal_starting_balance,
        comment: informal_comment,
        amount: informal_amount,
        frequency: 4,
        uh_id: informal_uh_id
      }, {
        start_date: formal_start_date,
        status: '600       ',
        breached: false,
        last_check_balance: formal_last_check_balance,
        last_check_date: '2014-11-30',
        last_check_expected_balance: formal_last_check_expected_balance,
        starting_balance: formal_starting_balance,
        comment: formal_comment,
        amount: formal_amount,
        frequency: 1,
        uh_id: formal_uh_id
      }]
    }

    before do
      expect(view_agreements).to receive(:execute).and_return([])
      expect(view_court_cases).to receive(:execute).and_return([court_case])
    end

    it 'migrates an informal and formal agreement' do
      expect(create_agreement).to receive(:create_agreement).with(
          {
          tenancy_ref: tenancy_ref,
          agreement_type: :informal,
          starting_balance: informal_starting_balance,
          amount: informal_amount,
          start_date: informal_start_date,
          frequency: 3,
          created_by: 'Managed Arrears migration from UH',
          notes: informal_comment,
          court_case_id: nil
        },
        starting_balance: informal_starting_balance,
        expected_balance: informal_last_check_expected_balance,
        checked_balance: informal_last_check_balance,
        description: 'Managed Arrears migration from UH',
        agreement_state: :cancelled
      ).and_return(informal_agreement)

      expect(create_agreement_migration).to receive(:execute).with(
        agreement_migration_params: {
          agreement_id: informal_agreement.id,
          legacy_id: informal_uh_id
        }
      )

      expect(create_agreement).to receive(:create_agreement).with(
        {
          tenancy_ref: tenancy_ref,
          agreement_type: :formal,
          starting_balance: formal_starting_balance,
          amount: formal_amount,
          start_date: formal_start_date,
          frequency: 0,
          created_by: 'Managed Arrears migration from UH',
          notes: formal_comment,
          court_case_id: court_case.id
        },
        starting_balance: formal_starting_balance,
        expected_balance: formal_last_check_expected_balance,
        checked_balance: formal_last_check_balance,
        description: 'Managed Arrears migration from UH',
        agreement_state: :completed
      ).and_return(formal_agreement)

      expect(create_agreement_migration).to receive(:execute).with(
        agreement_migration_params: {
          agreement_id: formal_agreement.id,
          legacy_id: formal_uh_id
        }
      )

      subject.migrate(tenancy_ref: tenancy_ref)
    end
  end
end
