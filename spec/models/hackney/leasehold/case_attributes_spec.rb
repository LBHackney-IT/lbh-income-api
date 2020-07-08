require 'rails_helper'

describe Hackney::Leasehold::CaseAttributes do
  before {
    described_class.delete_all
  }

  context 'when trying to create 2 tenancies with the same reference' do
    let(:tenancy_ref) { Faker::Internet.slug }

    before do
      described_class.create!(tenancy_ref: tenancy_ref)
    end

    it { expect(described_class.first).to be_a described_class }

    it 'throws an RecordNotUnique exception on the second insert' do
      expect do
        described_class.create!(tenancy_ref: tenancy_ref)
      end.to raise_error(ActiveRecord::RecordInvalid, /Validation failed: Tenancy ref/)
    end
  end

  context 'when there is a pause date paused' do
    let(:tenancy_ref) { Faker::Internet.slug }

    let(:leasehold_case_attributes) { described_class.create!(tenancy_ref: tenancy_ref, is_paused_until: pause_date) }

    context 'when the pause date is in the future' do
      let(:pause_date) { Faker::Date.forward(days: 23).to_s }

      it 'returns true' do
        expect(leasehold_case_attributes.paused?).to eq(true)
      end

      context 'when there\'s two cases, but only one is paused' do
        let(:tenancy_ref) { Faker::Internet.slug }

        let(:not_paused) { described_class.create!(tenancy_ref: tenancy_ref) }

        it 'returns only the not paused' do
          expect(described_class.not_paused).to eq([not_paused])
        end
      end
    end

    context 'when the pause date is in the past' do
      let(:pause_date) { Faker::Date.backward(days: 23).to_s }

      it 'returns true' do
        expect(leasehold_case_attributes.paused?).to eq(false)
      end
    end
  end
end
