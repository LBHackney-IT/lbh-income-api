require 'rails_helper'

describe Hackney::Income::UpdateCourtCase do
  subject { described_class.new }

  let(:id) { Faker::Number.number(digits: 2) }
  let(:tenancy_ref) { "#{Faker::Number.number(digits: 6)}/#{Faker::Number.number(digits: 2)}" }
  let(:court_date) { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }
  let(:court_outcome) { nil }
  let(:balance_on_court_outcome_date) { Faker::Commerce.price(range: 10...100) }
  let(:strike_out_date) { nil }
  let(:terms) { nil }
  let(:disrepair_counter_claim) { nil }

  let(:court_case_params) do
    {
      id: id,
      tenancy_ref: tenancy_ref,
      court_date: court_date,
      court_outcome: court_outcome,
      balance_on_court_outcome_date: balance_on_court_outcome_date,
      strike_out_date: strike_out_date,
      terms: terms,
      disrepair_counter_claim: disrepair_counter_claim
    }
  end

  before do
    create(:court_case, id: id, tenancy_ref: tenancy_ref, court_date: court_date)
  end

  context 'when adding an (not adjourned) court outcome to an existing court case' do
    let(:court_outcome) { 'SOT' }

    it 'updates and returns the court case' do
      court_case = subject.execute(court_case_params: court_case_params)

      expect(court_case).to be_an_instance_of(Hackney::Income::Models::CourtCase)
      expect(court_case.id).to eq(id)
      expect(court_case.tenancy_ref).to eq(tenancy_ref)
      expect(court_case.court_date).to eq(court_date)
      expect(court_case.court_outcome).to eq(court_outcome)
      expect(court_case.balance_on_court_outcome_date).to eq(balance_on_court_outcome_date)
    end
  end

  context 'when adding an adjourned court outcome to an existing court case' do
    let(:court_outcome) { 'AAH' }
    let(:strike_out_date) { Faker::Date.forward(days: 30) }
    let(:terms) { false }
    let(:disrepair_counter_claim) { false }

    it 'updates and returns the court case' do
      court_case = subject.execute(court_case_params: court_case_params)

      expect(court_case).to be_an_instance_of(Hackney::Income::Models::CourtCase)
      expect(court_case.id).to eq(id)
      expect(court_case.strike_out_date).to eq(strike_out_date)
      expect(court_case.terms).to eq(terms)
      expect(court_case.disrepair_counter_claim).to eq(disrepair_counter_claim)
    end
  end

  context 'when the court date of the existing court case does not match' do
    it 'updates the court date of the existing court case and returns it' do
      new_court_date = Faker::Date.between(from: 20.days.ago, to: 11.days.ago)
      court_case_params[:court_date] = new_court_date
      court_case = subject.execute(court_case_params: court_case_params)

      expect(court_case.id).to eq(id)
      expect(court_case.court_date).to eq(new_court_date)
    end
  end

  context 'when the court case does not exist' do
    it 'returns nil' do
      court_case_params[:id] = Faker::Number.number(digits: 6)

      expect(subject.execute(court_case_params: court_case_params)).to be_nil
    end
  end

  context 'when adding a court outcome without a court date to an existing court case' do
    it 'updates and returns the court case' do
      court_case = subject.execute(court_case_params: { id: id, court_date: nil, court_outcome: 'SOT' })

      expect(court_case.id).to eq(id)
      expect(court_case.court_date).not_to be_nil
      expect(court_case.court_outcome).to eq('SOT')
    end
  end
end
