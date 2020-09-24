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

  describe '#struck_out?' do
    it 'returns false if strike_out_date is nil' do
      expect(described_class.new(strike_out_date: nil).send(:struck_out?)).to be_falsey
    end

    it 'returns false if strike_out_date is in the future' do
      expect(described_class.new(strike_out_date: Date.today + 1.day).send(:struck_out?)).to be_falsey
    end

    it 'returns false if strike_out_date is on day or past' do
      expect(described_class.new(strike_out_date: Date.today).send(:struck_out?)).to be_truthy
    end
  end

  describe '#end_of_life?' do
    it 'returns false if court_date is nil' do
      expect(described_class.new(court_date: nil).send(:end_of_life?)).to be_falsey
    end

    it 'returns true if court_outcome is SUSPENSION_ON_TERMS and passed 6 years life' do
      expect(described_class.new(
        court_outcome: Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE,
        court_date: Date.today - 6.years
      ).send(:end_of_life?)).to be_falsey

      expect(described_class.new(
        court_outcome: Hackney::Tenancy::UpdatedCourtOutcomeCodes::SUSPENSION_ON_TERMS,
        court_date: Date.today - 6.years
      ).send(:end_of_life?)).to be_truthy
    end
  end

  describe '#expired?' do
    it 'returns true when a court case within life with terms' do
      allow(Hackney::Income::Models::CourtCase.new).to receive(:expired?).and_return(false)
      expect(described_class.new(terms: false)).not_to be_result_in_agreement
      expect(described_class.new(terms: true)).to be_result_in_agreement
    end
  end
end
