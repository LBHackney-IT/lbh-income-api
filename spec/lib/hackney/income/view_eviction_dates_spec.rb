require 'rails_helper'

describe Hackney::Income::ViewEvictionDates do
  subject { described_class.new.execute(tenancy_ref: tenancy_ref) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }

  context 'when there are no eviction dates for the tenancy' do
    it 'returns an empty array' do
      expect(subject).to eq([])
    end
  end

  context 'when there is an eviction date for a tenancy' do
    let(:eviction_date) { Faker::Date.between(from: 2.days.ago, to: Date.today).to_s }
    let(:eviction_date_params) do
      {

        tenancy_ref: tenancy_ref,
        eviction_date: eviction_date
      }
    end
    let!(:expected_eviction_date) { create(:eviction_date, eviction_date_params) }

    it 'returns returns an array of eviction dates for the given tenancy_ref' do
      response = subject

      expect(response.count).to eq(1)
      expect(response.first.id).to eq(expected_eviction_date.id)
      expect(response.first.tenancy_ref).to eq(tenancy_ref)
      expect(response.first.eviction_date).to eq(eviction_date)
    end
  end
end
