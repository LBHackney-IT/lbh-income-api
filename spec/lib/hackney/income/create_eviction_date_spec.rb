require 'rails_helper'

describe Hackney::Income::CreateEvictionDate do
  subject { described_class.new }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:eviction_date) { Faker::Date.between(from: 10.days.ago, to: 2.days.ago) }

  let(:new_eviction_date_params) do
  {
    tenancy_ref: tenancy_ref,
    eviction_date: eviction_date
  }
end

  it 'creates and returns a new eviction date' do
    new_eviction_date = subject.execute(eviction_date_params: new_eviction_date_params)

    eviction_date_id = Hackney::Income::Models::EvictionDate.where(tenancy_ref: tenancy_ref).last.id
    expect(new_eviction_date).to be_an_instance_of(Hackney::Income::Models::EvictionDate)
    expect(new_eviction_date.id).to eq(eviction_date_id)
    expect(new_eviction_date.tenancy_ref).to eq(tenancy_ref)
    expect(new_eviction_date.eviction_date).to eq(eviction_date)
  end
end
