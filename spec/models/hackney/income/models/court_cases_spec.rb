require 'rails_helper'

describe Hackney::Income::Models::CourtCase, type: :model do
  let(:valid_outcomes_without_terms) do
    [
      Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH,
      Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE,
      Hackney::Tenancy::UpdatedCourtOutcomeCodes::STRUCK_OUT,
      Hackney::Tenancy::UpdatedCourtOutcomeCodes::WITHDRAWN_ON_THE_DAY
    ].sample
  end
  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }

  it 'includes the fields for a court case' do
    court_case = described_class.new
    expect(court_case.attributes).to include(
      'tenancy_ref',
      'court_date',
      'court_outcome',
      'balance_on_court_outcome_date',
      'strike_out_date',
      'terms',
      'disrepair_counter_claim'
    )
  end

  it { is_expected.to validate_presence_of(:tenancy_ref) }
  it { is_expected.to have_many(:agreements) }

  it 'can have associated formal agreements' do
    court_case = described_class.create!(
      tenancy_ref: tenancy_ref,
      court_date: Faker::Date.between(from: 10.days.ago, to: 3.days.ago),
      court_outcome: valid_outcomes_without_terms,
      balance_on_court_outcome_date: Faker::Commerce.price(range: 10...100),
      strike_out_date: Faker::Date.forward(days: 365)
    )

    create(:agreement,
           tenancy_ref: tenancy_ref,
           current_state: :live,
           created_by: Faker::Name.name,
           agreement_type: :formal,
           court_case_id: court_case.id)

    expect(described_class.first.agreements.first).to be_a Hackney::Income::Models::Agreement
    expect(Hackney::Income::Models::Agreement.first.court_case).to eq(court_case)
  end

  context 'when there is a case priority' do
    let(:case_priority) { create(:case_priority, tenancy_ref: tenancy_ref, courtdate: nil, court_outcome: nil) }

    it 'updates the court case details on the existing case priority' do
      expected_court_date = Faker::Date.between(from: 10.days.ago, to: 3.days.ago)
      expected_court_outcome = valid_outcomes_without_terms

      expect(case_priority.courtdate).to be_nil
      expect(case_priority.court_outcome).to be_nil

      court_case = described_class.create!(
        tenancy_ref: tenancy_ref,
        court_date: expected_court_date,
        court_outcome: expected_court_outcome
      )

      case_priority.reload

      expect(case_priority.courtdate).to eq(expected_court_date)
      expect(case_priority.court_outcome).to eq(expected_court_outcome)

      updated_court_date = Faker::Date.between(from: 10.days.ago, to: 3.days.ago)
      updated_court_outcome = valid_outcomes_without_terms

      court_case.update!(court_outcome: updated_court_outcome, court_date: updated_court_date)

      case_priority.reload

      expect(case_priority.courtdate).to eq(updated_court_date)
      expect(case_priority.court_outcome).to eq(updated_court_outcome)
    end
  end

  context 'when there is only a court date (e.g. adding a court date before the case takes place)' do
    it 'is still a valid court case' do
      court_case = described_class.create!(
        tenancy_ref: tenancy_ref,
        court_date: Faker::Date.forward(days: 30)
      )

      expect(court_case).to be_a Hackney::Income::Models::CourtCase
    end
  end

  context 'when there is only a court outcome (e.g. court outcomes in UH)' do
    it 'is still a valid court case' do
      court_case = described_class.create!(
        tenancy_ref: tenancy_ref,
        court_outcome: valid_outcomes_without_terms
      )

      expect(court_case).to be_a Hackney::Income::Models::CourtCase
    end
  end

  context 'when the court outcome can have terms' do
    before { allow(subject).to receive(:can_have_terms?).and_return(true) }

    it { is_expected.to allow_value(%w[true false]).for(:terms) }
    it { is_expected.to allow_value(%w[true false]).for(:disrepair_counter_claim) }
  end

  context 'when the court outcome is invalid' do
    it 'raises an error' do
      expect { described_class.create!(tenancy_ref: tenancy_ref, court_outcome: 'invalid_outcome') }
        .to raise_error ActiveRecord::RecordInvalid,
                        'Validation failed: Court outcome must be a valid court outcome code'
    end
  end
end
