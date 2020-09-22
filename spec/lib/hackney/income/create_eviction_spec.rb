require 'rails_helper'

describe Hackney::Income::CreateEviction do
  subject { described_class.new }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:date) { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }

  let(:new_eviction_params) do
    {
      tenancy_ref: tenancy_ref,
      date: date
    }
  end

  it 'creates and returns a new eviction date' do
    new_eviction = subject.execute(eviction_params: new_eviction_params)

    eviction_id = Hackney::Income::Models::Eviction.where(tenancy_ref: tenancy_ref).last.id
    expect(new_eviction).to be_an_instance_of(Hackney::Income::Models::Eviction)
    expect(new_eviction.id).to eq(eviction_id)
    expect(new_eviction.tenancy_ref).to eq(tenancy_ref)
    expect(new_eviction.date).to eq(date)
  end
end
