require 'rails_helper'

describe Hackney::Income::CreateInformalAgreement do
  subject { described_class.new(add_action_diary: add_action_diary, cancel_agreement: cancel_agreement) }

  let(:cancel_agreement) { spy }
  let(:add_action_diary) { spy }
  let(:new_agreement_params) do
    {
      tenancy_ref: tenancy_ref,
      agreement_type: agreement_type,
      amount: amount,
      start_date: start_date,
      frequency: frequency,
      created_by: created_by,
      notes: notes
    }
  end
  let(:expected_action_diray_note) { "Informal agreement created: #{notes}" }
  let(:notes) { Faker::ChuckNorris.fact }
  let(:created_by) { Faker::Name.name }
  let(:frequency) { 'weekly' }
  let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:amount) { Faker::Commerce.price(range: 10...100) }
  let(:agreement_type) { 'informal' }
  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }

  it_behaves_like 'CreateAgreement'

  context 'when there is a previous breached agreement for the tenancy' do
    before do
      breached_agreement = Hackney::Income::Models::Agreement.create(
        tenancy_ref: tenancy_ref,
        current_state: 'breached',
        created_by: created_by,
        agreement_type: 'informal'
      )
      Hackney::Income::Models::AgreementState.create(agreement_id: breached_agreement.id, agreement_state: 'breached')
      Hackney::Income::Models::CasePriority.create!(tenancy_ref: tenancy_ref, balance: 200)
    end

    it 'cancelles the existing breached agreement and creates a new live agreement' do
      subject.execute(new_agreement_params: new_agreement_params)

      agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).includes(:agreement_states)

      expect(cancel_agreement).to have_received(:execute).with(agreement_id: agreements.first.id)

      expect(agreements.count).to eq(2)
      expect(agreements.second.current_state).to eq('live')
    end
  end

  context 'when there is an existing formal agreement for the tenancy' do
    let(:court_case) do
      Hackney::Income::Models::CourtCase.create!(
        tenancy_ref: tenancy_ref,
        balance_at_outcome_date: Faker::Commerce.price(range: 10...1000),
        court_decision_date: Faker::Date.between(from: 2.days.ago, to: Date.today),
        court_outcome: Faker::ChuckNorris.fact
      )
    end

    before do
      Hackney::Income::Models::CasePriority.create!(tenancy_ref: tenancy_ref, balance: 200)

      existing_agreement = Hackney::Income::Models::Agreement.create!(
        tenancy_ref: tenancy_ref,
        amount: Faker::Commerce.price(range: 10...100),
        start_date: Faker::Date.between(from: 4.days.ago, to: Date.today),
        frequency: frequency,
        created_by: created_by,
        agreement_type: 'formal',
        court_case_id: court_case.id,
        notes: notes
      )
      Hackney::Income::Models::AgreementState.create!(agreement_id: existing_agreement.id, agreement_state: :live)
    end

    it 'does not allow create a new informal agreement' do
      expect { subject.execute(new_agreement_params: new_agreement_params) }
        .to raise_error Hackney::Income::CreateInformalAgreement::CreateAgreementError, 'There is an existing formal agreement for this tenancy'
    end
  end
end
