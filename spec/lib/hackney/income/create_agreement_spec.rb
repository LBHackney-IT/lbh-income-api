require 'rails_helper'

describe Hackney::Income::CreateAgreement do
  subject { described_class.new }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:agreement_type) { 'informal' }
  let(:amount) { Faker::Commerce.price(range: 10...100) }
  let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:frequency) { 'weekly' }
  let(:created_by) { Faker::Name.name }

  let(:existing_agreement_params) do
    {
      tenancy_ref: tenancy_ref,
      agreement_type: 'formal',
      amount: Faker::Commerce.price(range: 10...100),
      start_date: Faker::Date.between(from: 4.days.ago, to: Date.today),
      frequency: frequency,
      created_by: created_by
    }
  end

  let(:new_agreement_params) do
    {
      tenancy_ref: tenancy_ref,
      agreement_type: agreement_type,
      amount: amount,
      start_date: start_date,
      frequency: frequency,
      created_by: created_by
    }
  end

  context 'when there are no previous agreements for the tenancy' do
    it 'creates and returns a new live agreement' do
      Hackney::Income::Models::CasePriority.create!(tenancy_ref: tenancy_ref, balance: 100)

      created_agreement = subject.execute(new_agreement_params: new_agreement_params)

      latest_agreement_id = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).first.id
      expect(created_agreement).to be_an_instance_of(Hackney::Income::Models::Agreement)
      expect(created_agreement.id).to eq(latest_agreement_id)
      expect(created_agreement.tenancy_ref).to eq(tenancy_ref)
      expect(created_agreement.agreement_type).to eq(agreement_type)
      expect(created_agreement.amount).to eq(amount)
      expect(created_agreement.start_date).to eq(start_date)
      expect(created_agreement.frequency).to eq(frequency)
      expect(created_agreement.current_state).to eq('live')
      expect(created_agreement.starting_balance).to eq(100)
      expect(created_agreement.created_by).to eq(created_by)
    end
  end

  context 'when there is a previous agreement for the tenancy' do
    it "creates and returns a new live agreement and the previous agreement's state is set to 'cancelled' " do
      Hackney::Income::Models::CasePriority.create!(tenancy_ref: tenancy_ref, balance: 200)

      existing_agreement = subject.execute(new_agreement_params: existing_agreement_params)
      new_agreement = subject.execute(new_agreement_params: new_agreement_params)

      agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).includes(:agreement_states)

      expect(agreements.count).to eq(2)

      expect(agreements.first.tenancy_ref).to eq(existing_agreement.tenancy_ref)
      expect(agreements.second.tenancy_ref).to eq(new_agreement.tenancy_ref)
      expect(agreements.first.current_state).to eq('cancelled')
    end
  end
end
