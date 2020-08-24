require 'rails_helper'

describe Hackney::Income::Models::CourtCase, type: :model do
  let(:valid_non_adjourned_outcome) do
    [
      Hackney::Tenancy::UpdatedCourtOutcomeCodes::SUSPENSION_ON_TERMS,
      Hackney::Tenancy::UpdatedCourtOutcomeCodes::STRUCK_OUT,
      Hackney::Tenancy::UpdatedCourtOutcomeCodes::WITHDRAWN_ON_THE_DAY,
      Hackney::Tenancy::UpdatedCourtOutcomeCodes::STAY_OF_EXECUTION
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
      court_outcome: valid_non_adjourned_outcome,
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
        court_outcome: valid_non_adjourned_outcome
      )

      expect(court_case).to be_a Hackney::Income::Models::CourtCase
    end
  end

  context 'when the court outcome is adjourned' do
    before { allow(subject).to receive(:adjourned?).and_return(true) }

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
