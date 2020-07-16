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
  let(:last_communication_date) { nil }
  let(:eviction_date) { nil }
  let(:courtdate) { nil }
  let(:court_outcome) { nil }
  let(:most_recent_agreement) { nil }
  let(:total_payment_amount_in_week) { 0 }
  let(:weekly_rent) { 0 }
  let(:balance) { 0 }
  let(:criteria) {
    Stubs::StubCriteria.new(
      eviction_date: eviction_date,
      courtdate: courtdate,
      court_outcome: court_outcome,
      last_communication_date: last_communication_date,
      most_recent_agreement: most_recent_agreement,
      total_payment_amount_in_week: total_payment_amount_in_week,
      weekly_rent: weekly_rent,
      balance: balance
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

  describe 'no_court_date?' do
    subject { helpers.no_court_date? }

    context 'when the criteria has a future court date' do
      let(:courtdate) { 6.days.from_now }

      it 'returns false' do
        expect(subject).to eq(false)
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

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end
  end

  describe 'last_communication_newer_than?' do
    subject { helpers.last_communication_newer_than? 2.months.ago }

    context 'when the criteria has a older communication date' do
      let(:last_communication_date) { 3.months.ago }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the criteria has a newer communication date' do
      let(:last_communication_date) { 1.month.ago }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the criteria does not have a communication date' do
      let(:last_communication_date) { nil }

      it 'returns false' do
        expect(subject).to eq(false)
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

  describe 'calculated_grace_amount' do
    subject { helpers.calculated_grace_amount }

    context 'when total payment amount not being above the weekly rent' do
      let(:total_payment_amount_in_week) { -5 }

      it 'return 0' do
        expect(subject).to eq(0)
      end
    end

    context 'when total payment amount is above the weekly rent' do
      let(:total_payment_amount_in_week) { 5 }
      let(:weekly_rent) { 5 }

      it 'returns the sum of gross rent and payment amount' do
        expect(subject).to eq(10)
      end
    end
  end

  describe 'balance_with_1_week_grace' do
    subject { helpers.balance_with_1_week_grace }

    context 'when total payment amount not being above the weekly rent' do
      let(:balance) { 15 }

      it 'return the difference between balance and grace amount' do
        allow(helpers).to receive(:calculated_grace_amount).and_return(5)
        expect(subject).to eq(10)
      end
    end
  end

  describe 'informal_breached_agreement?' do
    subject { helpers.informal_breached_agreement? }

    context 'when a case is either paused, has an eviction date or has a future court date' do
      it 'return false' do
        allow(helpers).to receive(:should_prevent_action?).and_return(true)
        expect(subject).to eq(false)
      end
    end

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

  describe 'balance_is_in_arrears_by_amount?' do
    subject { helpers.balance_is_in_arrears_by_amount?(amount) }

    let(:balance) { 15 }

    context 'when grace balance_with_1_week_grace is more than amount' do
      let(:amount) { 0 }

      it 'returns true' do
        allow(helpers).to receive(:balance_with_1_week_grace).and_return(5)

        expect(subject).to eq(true)
      end
    end

    context 'when grace balance_with_1_week_grace is less than amount' do
      let(:amount) { 30 }

      it 'returns false' do
        allow(helpers).to receive(:balance_with_1_week_grace).and_return(5)

        expect(subject).to eq(false)
      end
    end
  end

  describe 'arrear_accumulation_by_number_weeks' do
    subject { helpers.arrear_accumulation_by_number_weeks(weeks) }

    let(:weekly_rent) { 10 }

    context 'when grace balance_with_1_week_grace is more than amount' do
      let(:weeks) { 3 }

      it 'returns gross rent multiplied by weeks' do
        expect(subject).to eq(30)
      end
    end
  end

  describe 'balance_is_in_arrears_by_number_of_weeks?' do
    subject { helpers.balance_is_in_arrears_by_number_of_weeks?(2) }

    context 'when grace balance_with_1_week_grace is more than arrears accumulation by 2 weeks' do
      it 'returns true' do
        allow(helpers).to receive(:balance_with_1_week_grace).and_return(50)
        allow(helpers).to receive(:arrear_accumulation_by_number_weeks).and_return(15)

        expect(subject).to eq(true)
      end
    end

    context 'when grace balance_with_1_week_grace is less than arrears accumulation by 2 weeks' do
      it 'returns false' do
        allow(helpers).to receive(:balance_with_1_week_grace).and_return(5)
        allow(helpers).to receive(:arrear_accumulation_by_number_weeks).and_return(15)

        expect(subject).to eq(false)
      end
    end
  end

  describe 'court_warrant_active' do
    subject { helpers.court_warrant_active? }

    context 'when there is no court outcome' do
      let(:court_outcome) { nil }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is a adjourned on terms outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY }

      context 'with a court date 2 years ago' do
        let(:courtdate) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
      end

      context 'with a court date 8 years ago' do
        let(:courtdate) { 8.years.ago }

        it 'returns false' do
          expect(subject).to eq(false)
        end
      end

      context 'with a court date is nil' do
        let(:courtdate) { nil }

        it 'returns false' do
          expect(subject).to eq(true)
        end
      end
    end

    context 'when there is a adjourned on terms outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS }

      context 'with a court date 2 years ago' do
        let(:courtdate) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
      end

      context 'with a court date 8 years ago' do
        let(:courtdate) { 8.years.ago }

        it 'returns false' do
          expect(subject).to eq(false)
        end
      end
    end

    context 'when there is a adjourned (secondary) on terms outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS_SECONDARY }

      context 'with a court date 2 years ago' do
        let(:courtdate) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
      end

      context 'with a court date 8 years ago' do
        let(:courtdate) { 8.years.ago }

        it 'returns false' do
          expect(subject).to eq(false)
        end
      end
    end

    context 'when there is a suspended possession outcome outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::SUSPENDED_POSSESSION }

      context 'with a court date 2 years ago' do
        let(:courtdate) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
        context 'with a court date 8 years ago' do
          let(:courtdate) { 8.years.ago }

          it 'returns false' do
            expect(subject).to eq(false)
          end
        end
      end
    end

    context 'when there is a outright possession with date outcome outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE }

      context 'with a court date 2 years ago' do
        let(:courtdate) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
        context 'with a court date 8 years ago' do
          let(:courtdate) { 8.years.ago }

          it 'returns false' do
            expect(subject).to eq(false)
          end
        end
      end
    end

    context 'when there is a outright possession forthwith outcome outcome' do
      let(:court_outcome) { Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH }

      context 'with a court date 2 years ago' do
        let(:courtdate) { 2.years.ago }

        it 'returns true' do
          expect(subject).to eq(true)
        end
        context 'with a court date 8 years ago' do
          let(:courtdate) { 8.years.ago }

          it 'returns false' do
            expect(subject).to eq(false)
          end
        end
      end
    end
  end

  describe 'court_outcome_missing?' do
    subject { helpers.court_outcome_missing? }

    context 'when there is no court date' do
      let(:courtdate) { nil }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is a court date in the past' do
      let(:courtdate) { 2.days.ago }

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
      let(:courtdate) { 2.days.ago }

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

  describe 'active_agreement' do
    subject { helpers.active_agreement? }

    context 'when there is no agreement' do
      let(:most_recent_agreement) { nil }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when there is an active non-breached agreement' do
      let(:most_recent_agreement) { { start_date: 1.week.ago, breached: false, status: :active } }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when there is a breached agreement' do
      let(:most_recent_agreement) { { start_date: 1.week.ago, breached: true, status: :breached } }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end
  end
end
