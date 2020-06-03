require 'rails_helper'

describe Hackney::Income::TenancyClassification::V2::Helpers do
  let(:case_priority) { build(:case_priority, is_paused_until: nil) }
  let(:eviction_date) { nil }
  let(:criteria) {
    Stubs::StubCriteria.new(
      eviction_date: eviction_date
    )
  }

  let(:helpers) { described_class.new(case_priority, criteria, nil) }

  describe 'case_paused?' do
    subject { helpers.case_paused? }

    context 'when a case is paused for seven days' do
      let(:case_priority) { build(:case_priority, is_paused_until: 7.days.from_now) }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when a case was paused in the past' do
      let(:case_priority) { build(:case_priority, is_paused_until: 7.days.ago) }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe 'case_has_eviction_date?' do
    subject { helpers.case_has_eviction_date? }

    context 'when the criteria has a future eviction date' do
      let(:eviction_date) { 6.days.from_now }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the criteria has a past eviction date' do
      let(:eviction_date) { 6.days.ago }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the criteria does not have a eviction date' do
      let(:eviction_date) { nil }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end
end
