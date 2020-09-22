require 'rails_helper'

describe Hackney::Income::ViewEvictions do
  subject { described_class.new.execute(tenancy_ref: tenancy_ref) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }

  context 'when there are no evictions for the tenancy' do
    it 'returns an empty array' do
      expect(subject).to eq([])
    end
  end

  context 'when there is an eviction for a tenancy' do
    let(:date) { Faker::Date.between(from: 2.days.ago, to: Date.today).to_s }
    let(:eviction_params) do
      {

        tenancy_ref: tenancy_ref,
        date: date
      }
    end
    let!(:expected_eviction) { create(:eviction, eviction_params) }

    it 'returns returns an array of eviction dates for the given tenancy_ref' do
      response = subject

      expect(response.count).to eq(1)
      expect(response.first.id).to eq(expected_eviction.id)
      expect(response.first.tenancy_ref).to eq(tenancy_ref)
      expect(response.first.date).to eq(date)
    end
  end
end
