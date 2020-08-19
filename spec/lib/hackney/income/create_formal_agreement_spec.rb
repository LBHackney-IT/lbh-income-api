require 'rails_helper'

describe Hackney::Income::CreateFormalAgreement do
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
      court_case_id: court_case.id,
      notes: notes
    }
  end
  let(:court_case) do
    Hackney::Income::Models::CourtCase.create!(
      tenancy_ref: tenancy_ref,
      balance_on_court_outcome_date: Faker::Commerce.price(range: 10...1000),
      court_date: Faker::Date.between(from: 2.days.ago, to: Date.today),
      court_outcome: 'MAA',
      strike_out_date: Faker::Date.forward(days: 365)
    )
  end
  let(:expected_action_diray_note) { "Formal agreement created: #{notes}" }
  let(:notes) { Faker::ChuckNorris.fact }
  let(:created_by) { Faker::Name.name }
  let(:frequency) { 'weekly' }
  let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:amount) { Faker::Commerce.price(range: 10...100) }
  let(:agreement_type) { 'formal' }
  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }

  it_behaves_like 'CreateAgreement'

  context 'when the court case id is missing' do
    before do
      new_agreement_params[:court_case_id] = nil
    end

    it 'returns nil' do
      expect(subject.execute(new_agreement_params: new_agreement_params)).to be_nil
    end
  end

  context 'when the court case id is invalid' do
    before do
      new_agreement_params[:court_case_id] = 'does not exist'
    end

    it 'returns nil' do
      expect(subject.execute(new_agreement_params: new_agreement_params)).to be_nil
    end
  end

  context 'when there are no previous agreements for the tenancy' do
    it 'creates and returns a new formal agreement with a court case id' do
      Hackney::Income::Models::CasePriority.create!(tenancy_ref: tenancy_ref, balance: 100)

      created_agreement = subject.execute(new_agreement_params: new_agreement_params)

      expect(created_agreement.court_case_id).to eq(court_case.id)
    end
  end
end
