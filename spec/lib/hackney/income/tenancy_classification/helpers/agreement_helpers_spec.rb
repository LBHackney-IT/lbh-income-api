require 'rails_helper'

describe Hackney::Income::TenancyClassification::Helpers::AgreementHelpers do
  class DummyAgreementHelperClass
    include Hackney::Income::TenancyClassification::Helpers::AgreementHelpers

    def initialize(case_priority, criteria, documents)
      @case_priority = case_priority
      @criteria = criteria
      @documents = documents
      @use_ma_data = true # This will call MAAgreementHelpers trough the HelpersProxy class
    end
  end
  let(:agreement_model) { Hackney::Income::Models::Agreement }
  let(:court_case_model) { Hackney::Income::Models::CourtCase }
  let(:case_priority) { build(:case_priority, is_paused_until: nil) }
  let(:criteria) { Stubs::StubCriteria.new }
  let(:helpers) { DummyAgreementHelperClass.new(case_priority, criteria, nil) }
  let(:most_recent_agreement) { nil }

  before do
    unless most_recent_agreement.nil?
      agreement = build(:agreement, tenancy_ref: criteria.tenancy_ref,
                                    start_date: most_recent_agreement[:start_date],
                                    current_state: most_recent_agreement[:state],
                                    agreement_type: most_recent_agreement[:agreement_type])
      allow(agreement_model).to receive(:where).with(tenancy_ref: criteria.tenancy_ref).and_return([agreement])
    end
  end

  describe 'breached_agreement?' do
    subject { helpers.breached_agreement? }

    context 'when a case doesnt have a recent agreement' do
      let(:most_recent_agreement) { nil }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is an agreement and it has been breached' do
      let(:most_recent_agreement) { { start_date: 1.week.ago, state: :breached } }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when there is an agreement and it has not been breached' do
      let(:most_recent_agreement) { { start_date: 1.week.ago, state: :live } }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe 'court_breach_agreement?' do
    subject { helpers.court_breach_agreement? }

    let(:most_recent_agreement) { { start_date: start_date, agreement_type: agreement_type, state: state } }
    let(:agreement_type) { :formal }
    let(:start_date) { 1.week.ago.to_date }
    let(:state) { :live }
    let(:court_date) { nil }

    before do
      unless court_date.nil?
        court_case = build(:court_case, tenancy_ref: criteria.tenancy_ref,
                                        court_date: court_date)
        allow(court_case_model).to receive(:where).with(tenancy_ref: criteria.tenancy_ref).and_return([court_case])
      end
    end

    context 'when an agreement has not been breached' do
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there its an informal agreement' do
      let(:state) { :breached }
      let(:agreement_type) { :informal }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the agreement start date is ahead of the courtdate' do
      let(:court_date) { 2.weeks.ago }
      let(:state) { :breached }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the agreement start date is before the courtdate' do
      let(:court_date) { 6.days.ago }
      let(:state) { :breached }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the agreement start date is the same as the courtdate' do
      let(:court_date) { 1.week.ago.to_date }
      let(:breached) { true }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe 'informal_breached_agreement?' do
    subject { helpers.informal_breached_agreement? }

    context 'when there is an agreement and it has not been breached' do
      it 'returns false' do
        allow(helpers).to receive(:breached_agreement?).and_return(false)

        expect(subject).to eq(false)
      end
    end

    context 'when there is an agreement is court ordered' do
      it 'returns false' do
        allow(helpers).to receive(:court_breach_agreement?).and_return(true)

        expect(subject).to eq(false)
      end
    end

    context 'when agreemnt is not court ordered and it breached' do
      it 'returns false' do
        allow(helpers).to receive(:court_breach_agreement?).and_return(false)
        allow(helpers).to receive(:breached_agreement?).and_return(true)

        expect(subject).to eq(true)
      end
    end
  end

  describe 'active_agreement' do
    subject { helpers.active_agreement? }

    context 'when there is no agreement' do
      let(:most_recent_agreement) { nil }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is an active non-breached agreement' do
      let(:most_recent_agreement) { { start_date: 1.week.ago, state: :live } }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when there is a breached agreement' do
      let(:most_recent_agreement) { { start_date: 1.week.ago, state: :breached } }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end
  end
end
