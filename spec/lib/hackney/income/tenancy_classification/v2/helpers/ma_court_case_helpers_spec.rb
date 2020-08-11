require 'rails_helper'

describe Hackney::Income::TenancyClassification::V2::Helpers::MACourtCaseHelpers do
  class DummyCourtCaseHelperClass
    include Hackney::Income::TenancyClassification::V2::Helpers::MACourtCaseHelpers

    def initialize(case_priority, criteria, documents)
      @case_priority = case_priority
      @criteria = criteria
      @documents = documents
    end
  end

  let(:court_case_model) { Hackney::Income::Models::CourtCase }
  let(:case_priority) { build(:case_priority, is_paused_until: nil) }
  let(:criteria) { Stubs::StubCriteria.new }
  let(:helpers) { DummyCourtCaseHelperClass.new(case_priority, criteria, nil) }
  let(:most_recent_court_case) { nil }

  before do
    unless most_recent_court_case.nil?
      court_case = build(:court_case, tenancy_ref: criteria.tenancy_ref,
                                      court_date: most_recent_court_case[:court_date],
                                      court_outcome: most_recent_court_case[:court_outcome])
      allow(court_case_model).to receive(:where).with(tenancy_ref: criteria.tenancy_ref).and_return([court_case])
    end
  end

  describe 'court_date_in_future' do
    subject { helpers.court_date_in_future? }

    context 'when there is no court case' do
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the court case has a future court date' do
      let(:most_recent_court_case) { { court_date: 6.days.from_now } }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the court case has a past court date' do
      let(:most_recent_court_case) { { court_date: 6.days.ago } }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the court case does not have a court date' do
      let(:most_recent_court_case) { { court_date: nil } }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe 'no_court_date?' do
    subject { helpers.no_court_date? }

    context 'when there is no court case' do
      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the court case has a future court date' do
      let(:most_recent_court_case) { { court_date: 6.days.from_now } }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the court case has a past court date' do
      let(:most_recent_court_case) { { court_date: 6.days.ago } }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the court case does not have a court date' do
      let(:most_recent_court_case) { { court_date: nil } }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end
  end

  describe 'court_warrant_active?' do
    subject { helpers.court_warrant_active? }

    context 'when there is no court case' do
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is no court outcome' do
      let(:most_recent_court_case) { { court_outcome: nil } }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is a adjourned on terms outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY }
      let(:most_recent_court_case) { { court_outcome: court_outcome, court_date: court_date } }

      context 'with a court date 2 years ago' do
        let(:court_date) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
      end

      context 'with a court date 8 years ago' do
        let(:court_date) { 8.years.ago }

        it 'returns false' do
          expect(subject).to eq(false)
        end
      end

      context 'with a court date is nil' do
        let(:court_date) { nil }

        it 'returns false' do
          expect(subject).to eq(true)
        end
      end
    end

    context 'when there is a adjourned on terms outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS }
      let(:most_recent_court_case) { { court_outcome: court_outcome, court_date: court_date } }

      context 'with a court date 2 years ago' do
        let(:court_date) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
      end

      context 'with a court date 8 years ago' do
        let(:court_date) { 8.years.ago }

        it 'returns false' do
          expect(subject).to eq(false)
        end
      end
    end

    context 'when there is a adjourned (secondary) on terms outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS_SECONDARY }
      let(:most_recent_court_case) { { court_outcome: court_outcome, court_date: court_date } }

      context 'with a court date 2 years ago' do
        let(:court_date) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
      end

      context 'with a court date 8 years ago' do
        let(:court_date) { 8.years.ago }

        it 'returns false' do
          expect(subject).to eq(false)
        end
      end
    end

    context 'when there is a suspended possession outcome outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::SUSPENDED_POSSESSION }
      let(:most_recent_court_case) { { court_outcome: court_outcome, court_date: court_date } }

      context 'with a court date 2 years ago' do
        let(:court_date) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
        context 'with a court date 8 years ago' do
          let(:court_date) { 8.years.ago }

          it 'returns false' do
            expect(subject).to eq(false)
          end
        end
      end
    end

    context 'when there is a outright possession with date outcome outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE }
      let(:most_recent_court_case) { { court_outcome: court_outcome, court_date: court_date } }

      context 'with a court date 2 years ago' do
        let(:court_date) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
        context 'with a court date 8 years ago' do
          let(:court_date) { 8.years.ago }

          it 'returns false' do
            expect(subject).to eq(false)
          end
        end
      end
    end

    context 'when there is a outright possession forthwith outcome outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH }
      let(:most_recent_court_case) { { court_outcome: court_outcome, court_date: court_date } }

      context 'with a court date 2 years ago' do
        let(:court_date) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
        context 'with a court date 8 years ago' do
          let(:court_date) { 8.years.ago }

          it 'returns false' do
            expect(subject).to eq(false)
          end
        end
      end
    end
  end

  describe 'court_outcome_missing?' do
    subject { helpers.court_outcome_missing? }

    context 'when there is no court case' do
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is no court date' do
      let(:most_recent_court_case) { { court_date: nil } }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is a court date in the past' do
      let(:most_recent_court_case) { { court_outcome: court_outcome, court_date: court_date } }
      let(:court_date) { 2.days.ago }

      context 'when the court outcome is blank' do
        let(:court_outcome) { nil }

        it 'returns true' do
          expect(subject).to eq(true)
        end
      end

      context 'when the court outcome is not blank' do
        let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE }

        it 'returns false' do
          expect(subject).to eq(false)
        end
      end
    end

    context 'when there is a court date in the future' do
      let(:most_recent_court_case) { { court_outcome: court_outcome, court_date: court_date } }
      let(:court_date) { 2.days.ago }

      context 'when the court outcome is blank' do
        let(:court_outcome) { nil }

        it 'returns false' do
          expect(subject).to eq(true)
        end
      end

      context 'when the court outcome is not blank' do
        let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE }

        it 'returns false' do
          expect(subject).to eq(false)
        end
      end
    end
  end
end
