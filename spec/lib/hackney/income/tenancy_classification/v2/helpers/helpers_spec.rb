require 'rails_helper'

describe Hackney::Income::TenancyClassification::V2::Helpers do
  let(:case_priority) { build(:case_priority, is_paused_until: nil) }
  let(:eviction_date) { nil }
  let(:courtdate) { nil }
  let(:criteria) {
    Stubs::StubCriteria.new(
      eviction_date: eviction_date,
      courtdate: courtdate
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

  describe 'court_date_in_future' do
    subject { helpers.court_date_in_future? }

    context 'when the criteria has a future court date' do
      let(:courtdate) { 6.days.from_now }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the criteria has a past court date' do
      let(:courtdate) { 6.days.ago }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the criteria does not have a court date' do
      let(:courtdate) { nil }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe 'should_prevent_action?' do
    subject { helpers.should_prevent_action? }

    context 'when the case does not have a future court date, and does not have an eviction date, and is not paused' do
      let(:courtdate) { nil }
      let(:eviction_date) { nil }
      let(:case_priority) { build(:case_priority, is_paused_until: nil) }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the case does have a future court date' do
      let(:courtdate) { 7.days.from_now }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the case does have an eviction date' do
      let(:eviction_date) { 7.days.from_now }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the case is paused' do
      let(:case_priority) { build(:case_priority, is_paused_until: 7.days.from_now) }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end
  end
end
