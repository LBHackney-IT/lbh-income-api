require 'rails_helper'

describe Hackney::Income::TenancyClassification::V2::Helpers do
  class HelperClass
    include Hackney::Income::TenancyClassification::V2::Helpers

    def initialize(case_priority, criteria, documents)
      @case_priority = case_priority
      @criteria = criteria
      @documents = documents
    end
  end

  let(:case_priority) { build(:case_priority, is_paused_until: nil) }
  let(:eviction_date) { nil }
  let(:courtdate) { nil }
  let(:last_communication_date) { nil }
  let(:most_recent_agreement) { nil }
  let(:criteria) {
    Stubs::StubCriteria.new(
      eviction_date: eviction_date,
      courtdate: courtdate,
      last_communication_date: last_communication_date,
      most_recent_agreement: most_recent_agreement
    )
  }

  let(:helpers) { HelperClass.new(case_priority, criteria, nil) }

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

  describe 'last_communication_older_than?' do
    subject { helpers.last_communication_older_than? 1.month.ago }

    context 'when a cases last communication date was in the past' do
      let(:last_communication_date) { 2.months.ago }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when a cases last communication date is today' do
      let(:last_communication_date) { 1.month.ago.to_date }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when a cases last communication date is in the future' do
      let(:last_communication_date) { 1.month.from_now }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is no last communication date for a case' do
      let(:last_communication_date) { nil }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe 'last_communication_newer_than?' do
    subject { helpers.last_communication_newer_than? 3.month.ago }

    context 'when there is no last communication date for a case' do
      let(:last_communication_date) { nil }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the last communication happend a couple of months ago' do
      let(:last_communication_date) { 4.months.ago }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the last communication was a month ago' do
      let(:last_communication_date) { 1.month.ago }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end
  end

  describe 'breached_agreement?' do
    subject { helpers.breached_agreement? }

    context 'when a case is either paused, has an eviction date or has a future court date' do
      let(:most_recent_agreement) { { start_date: 1.week.ago, breached: false } }

      it 'returns false' do
        allow(helpers).to receive(:should_prevent_action?).and_return(true)
        expect(subject).to eq(false)
      end
    end

    context 'when a case doesnt have a recent agreement' do
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the most recent agreement does not have a start date' do
      let(:most_recent_agreement) { { start_date: nil, breached: true } }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is an agreement and it has been breached' do
      let(:most_recent_agreement) { { start_date: 1.week.ago, breached: true } }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when there is an agreement and it has not been breached' do
      let(:most_recent_agreement) { { start_date: 1.week.ago, breached: false } }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe 'court_breach_agreement?' do
    subject { helpers.court_breach_agreement? }

    let(:most_recent_agreement) { { start_date: start_date, breached: breached } }
    let(:start_date) { 1.week.ago.to_date }
    let(:breached) { false }

    context 'when a case is either paused, has an eviction date or has a future court date' do
      it 'returns false' do
        allow(helpers).to receive(:should_prevent_action?).and_return(true)
        expect(subject).to eq(false)
      end
    end

    context 'when an agreement has not been breached' do
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is no courtdate' do
      let(:breached) { true }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the agreement start date is ahead of the courtdate' do
      let(:courtdate) { 2.weeks.ago }
      let(:breached) { true }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the agreement start date is before the courtdate' do
      let(:courtdate) { 6.days.ago }
      let(:breached) { true }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the agreement start date is the same as the courtdate' do
      let(:courtdate) { 1.week.ago.to_date }
      let(:breached) { true }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end
end
