require 'rails_helper'

describe Hackney::Income::ViewAgreements do
  subject { described_class.execute(tenancy_ref: tenancy_ref) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:agreement_type) { 'formal' }
  let(:starting_balance) { Faker::Commerce.price(range: 10...1000) }
  let(:amount) { Faker::Commerce.price(range: 10...100) }
  let(:start_date) { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  let(:frequency) { 'weekly' }
  let(:new_state) { 'active' }
  let(:old_state) { 'breached' }
  let(:agreement_params) do
    {
      tenancy_ref: tenancy_ref,
      agreement_type: agreement_type,
      starting_balance: starting_balance,
      amount: amount,
      start_date: start_date,
      frequency: frequency
    }
  end

  it 'returns all agreements with the given tenancy_ref' do
    Hackney::Income::Models::Agreement.create!(agreement_params)
    # TODO
    # setup agreement_state history and current_state
    # Hackney::Income::Models::AgreementState.create!(agreement_id: first_agreement.id, state: new_state)

    response = subject

    expect(response[:agreements].count).to eq(1)
    expect(response[:agreements].first[:tenancyRef]).to eq(tenancy_ref)
    expect(response[:agreements].first[:agreementType]).to eq(agreement_type)
    expect(response[:agreements].first[:startingBalance]).to eq(starting_balance)
    expect(response[:agreements].first[:amount]).to eq(amount)
    expect(response[:agreements].first[:startDate]).to eq(start_date)
    expect(response[:agreements].first[:frequency]).to eq(frequency)
    expect(response[:agreements].first[:history]).to eq([])
  end
end
