require 'rails_helper'

describe Hackney::Income::TenancyClassification::V2::Helpers do
  describe 'case_paused?' do
    subject { helpers.case_paused? }

    let(:helpers) { described_class.new(case_priority, nil, nil) }

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
end
