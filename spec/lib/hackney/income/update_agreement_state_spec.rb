require 'rails_helper'

describe Hackney::Income::UpdateAgreementState do
  subject { described_class.new(tolerance_days: days_before_check) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:days_before_check) { 5 }
  let(:start_date) { Time.zone.local(2019, 11, 1) }

  it 'allows a number of days before checking for breach' do
    start_date = Time.zone.local(2019, 11, 1)
    starting_balance = 100
    agreement = stub_informal_agreement(
      start_date: start_date,
      frequency: :monthly,
      amount: 50,
      starting_balance: starting_balance
    )

    date_within_tolerance = start_date + (days_before_check - 1).days

    Timecop.freeze(date_within_tolerance) do
      subject.execute(agreement: agreement, current_balance: starting_balance)

      expect(agreement.current_state).to eq('live')
    end

    date_beyond_tolerance = start_date + days_before_check.days

    Timecop.freeze(date_beyond_tolerance) do
      subject.execute(agreement: agreement, current_balance: starting_balance)

      expect(agreement.current_state).to eq('breached')
    end
  end

  context 'when the agreement has an inactive state' do
    let(:agreement) { build_stubbed(:agreement) }

    it 'returns false' do
      expect(subject.execute(agreement: agreement, current_balance: 'DUMMY')).to be_falsy
    end
  end

  context 'when the agreement is not breached' do
    let!(:agreement) do
      stub_informal_agreement(
        start_date: start_date,
        frequency: :monthly,
        amount: 20,
        starting_balance: 100
      )
    end

    it 'updates the last_checked date when the status has not changed' do
      last_checked_balance = 80
      create(:agreement_state,
             :live,
             agreement: agreement,
             expected_balance: last_checked_balance,
             checked_balance: last_checked_balance)

      check_date = start_date + days_before_check.days

      Timecop.freeze(check_date) do
        subject.execute(agreement: agreement, current_balance: last_checked_balance)
        expect(agreement.agreement_states.count).to eq(2)
        expect(agreement.current_state).to eq('live')
        expect(agreement.last_checked).to eq(check_date)
      end
    end

    it 'add a new status when the status has changed' do
      check_date = start_date + 2.months

      Timecop.freeze(check_date) do
        subject.execute(agreement: agreement, current_balance: 60)
        expect(agreement.agreement_states.count).to eq(2)
        expect(agreement.agreement_states.last.expected_balance).to eq(60)
        expect(agreement.agreement_states.last.checked_balance).to eq(60)
        expect(agreement.agreement_states.last.description).to eq('Checked by the system')
        expect(agreement.current_state).to eq('live')
        expect(agreement.last_checked).to eq(check_date)
      end
    end
  end

  context 'when the frequency of payment is :monthly' do
    it 'updates the state of the agreement when its breached' do
      agreement = stub_informal_agreement(
        start_date: start_date,
        frequency: :monthly,
        amount: 20,
        starting_balance: 100
      )

      one_month_later = start_date + days_before_check.days + 1.month
      one_day_before_next_cycle = one_month_later - 1.day

      Timecop.freeze(one_day_before_next_cycle) do
        subject.execute(agreement: agreement, current_balance: 80)

        expect(agreement.current_state).to eq('live')
      end

      Timecop.freeze(one_month_later) do
        subject.execute(agreement: agreement, current_balance: 80)

        expect(agreement.current_state).to eq('breached')
      end
    end
  end

  context 'when the frequency of payment is :weekly' do
    it 'updates the state of the agreement when its breached' do
      agreement = stub_informal_agreement(
        start_date: start_date,
        frequency: :weekly,
        amount: 20,
        starting_balance: 100
      )

      three_weeks_later = start_date + days_before_check.days + 3.weeks
      one_day_before_next_cycle = three_weeks_later - 1.day

      Timecop.freeze(one_day_before_next_cycle) do
        subject.execute(agreement: agreement, current_balance: 40)

        expect(agreement.current_state).to eq('live')
      end

      Timecop.freeze(three_weeks_later) do
        subject.execute(agreement: agreement, current_balance: 40)

        expect(agreement.current_state).to eq('breached')
      end
    end
  end

  context 'when the frequency of payment is :fortnightly' do
    it 'updates the state of the agreement when its breached' do
      agreement = stub_informal_agreement(
        start_date: start_date,
        frequency: :fortnightly,
        amount: 20,
        starting_balance: 100
      )

      current_balance = 80

      two_weeks_later = start_date + days_before_check.days + 2.weeks
      one_day_before_next_cycle = two_weeks_later - 1.day

      Timecop.freeze(one_day_before_next_cycle) do
        subject.execute(agreement: agreement, current_balance: current_balance)

        expect(agreement.current_state).to eq('live')
      end

      Timecop.freeze(two_weeks_later) do
        subject.execute(agreement: agreement, current_balance: current_balance)

        expect(agreement.current_state).to eq('breached')
      end
    end
  end

  context "when the frequency of payment is '4 weekly'" do
    it 'updates the state of the agreement when its breached' do
      agreement = stub_informal_agreement(
        start_date: start_date,
        frequency: '4 weekly',
        amount: 20,
        starting_balance: 100
      )

      current_balance = 60

      eight_weeks_later = start_date + days_before_check.days + 8.weeks
      one_day_before_next_cycle = eight_weeks_later - 1.day

      Timecop.freeze(one_day_before_next_cycle) do
        subject.execute(agreement: agreement, current_balance: current_balance)

        expect(agreement.current_state).to eq('live')
      end

      Timecop.freeze(eight_weeks_later) do
        subject.execute(agreement: agreement, current_balance: current_balance)

        expect(agreement.current_state).to eq('breached')
      end
    end
  end

  context 'when the agreement is already breached' do
    let(:agreement) do
      stub_informal_agreement(
        start_date: start_date,
        frequency: :monthly,
        amount: 500,
        starting_balance: 1000
      )
    end
    let(:balance_at_last_check) { 1000 }

    before do
      create(:agreement_state,
             :breached,
             agreement: agreement,
             expected_balance: 500,
             checked_balance: 1000)
    end

    it 'resets the agreement state to live if no longer in breach' do
      Timecop.freeze(start_date + days_before_check.days) do
        current_balance = 500
        subject.execute(agreement: agreement, current_balance: current_balance)
        expect(agreement.current_state).to eq('live')
      end
    end

    it 'updates the last_checked date when the status has not changed' do
      check_date = start_date + 1.month

      Timecop.freeze(check_date) do
        subject.execute(agreement: agreement, current_balance: balance_at_last_check)
        expect(agreement.agreement_states.count).to eq(2)
        expect(agreement.current_state).to eq('breached')
        expect(agreement.last_checked).to eq(check_date)
      end
    end

    it 'add a new status when the status has changed' do
      check_date = start_date + 2.months

      Timecop.freeze(check_date) do
        current_balance = 500
        subject.execute(agreement: agreement, current_balance: current_balance)
        expect(agreement.agreement_states.count).to eq(3)
        expect(agreement.agreement_states.last.expected_balance).to eq(0)
        expect(agreement.agreement_states.last.checked_balance).to eq(current_balance)
        expect(agreement.agreement_states.last.description).to eq('Breached by £500.0')
        expect(agreement.current_state).to eq('breached')
        expect(agreement.last_checked).to eq(check_date)
      end

      Timecop.freeze(check_date + 3.months) do
        current_balance = 200.55
        subject.execute(agreement: agreement, current_balance: current_balance)
        expect(agreement.agreement_states.count).to eq(4)
        expect(agreement.agreement_states.last.expected_balance).to eq(0)
        expect(agreement.agreement_states.last.checked_balance).to eq(current_balance)
        expect(agreement.agreement_states.last.description).to eq('Breached by £200.55')
        expect(agreement.current_state).to eq('breached')
        expect(agreement.last_checked).to eq(check_date + 3.months)
      end
    end
  end

  context 'when all arrears has been recovered' do
    it 'updates the state of the agreement to completed' do
      agreement = stub_informal_agreement(
        start_date: start_date,
        frequency: '4 weekly',
        amount: 20,
        starting_balance: 100
      )
      current_balance = 0

      next_check_date = start_date + days_before_check.days

      Timecop.freeze(next_check_date) do
        subject.execute(agreement: agreement, current_balance: current_balance)
        expect(agreement.agreement_states.count).to eq(2)
        expect(agreement.agreement_states.last.expected_balance).to eq(80)
        expect(agreement.agreement_states.last.checked_balance).to eq(current_balance)
        expect(agreement.agreement_states.last.description).to eq(next_check_date.strftime('Completed on %m/%d/%Y'))
        expect(agreement.current_state).to eq('completed')
        expect(agreement.last_checked).to eq(next_check_date)
      end
    end
  end

  context 'when its a formal agreement' do
    it 'changes the formal agreement into informal on strikeout date' do
      next_check_date = start_date + days_before_check.days

      court_case = create(:court_case, tenancy_ref: tenancy_ref, strike_out_date: next_check_date)
      agreement = create(:agreement, agreement_type: :formal,
                                     start_date: start_date,
                                     tenancy_ref: tenancy_ref,
                                     court_case_id: court_case.id)
      create(:agreement_state, :live, agreement: agreement)

      current_balance = 50

      Timecop.freeze(next_check_date) do
        subject.execute(agreement: agreement, current_balance: current_balance)
        expect(agreement.agreement_type).to eq('informal')
      end
    end

    context 'when the court outcome is suspended on terms' do
      let(:court_outcome) { Hackney::Tenancy::UpdatedCourtOutcomeCodes::SUSPENSION_ON_TERMS }
      let(:next_check_date) { start_date + days_before_check.days }
      let(:court_case) do
        create(:court_case,
               tenancy_ref: tenancy_ref,
               court_outcome: court_outcome,
               court_date: court_date)
      end
      let(:agreement) do
        create(:agreement, agreement_type: :formal,
                           start_date: start_date,
                           tenancy_ref: tenancy_ref,
                           court_case_id: court_case.id)
      end

      context 'when its 6 years after the court hearing date' do
        let(:court_date) { next_check_date - 6.years }

        it 'completes the agreement' do
          create(:agreement_state, :live, agreement: agreement)
          next_check_date = start_date + days_before_check.days

          current_balance = 1000

          Timecop.freeze(next_check_date) do
            subject.execute(agreement: agreement, current_balance: current_balance)
            expect(agreement.current_state).to eq('completed')
            expect(agreement.last_checked).to eq(next_check_date)
            expect(agreement.agreement_states.last.description).to eq(next_check_date.strftime('Completed on %m/%d/%Y'))
          end
        end
      end

      context 'when its withing the 6 years lifecycle' do
        let(:court_date) { next_check_date - 5.years }

        it 'breaches the agreement when its in arrears' do
          create(:agreement_state, :live, agreement: agreement)
          next_check_date = start_date + days_before_check.days

          current_balance = 1000

          Timecop.freeze(next_check_date) do
            subject.execute(agreement: agreement, current_balance: current_balance)
            expect(agreement.current_state).to eq('breached')
          end
        end

        it 'completes when its not longer in arrears ' do
          create(:agreement_state, :live, agreement: agreement)
          next_check_date = start_date + days_before_check.days

          current_balance = 0

          Timecop.freeze(next_check_date) do
            subject.execute(agreement: agreement, current_balance: current_balance)
            expect(agreement.current_state).to eq('completed')
          end
        end
      end
    end
  end

  describe '#full_months_since' do
    it 'can calculate the exact number of months since start date' do
      [
        {
          start_date: Time.zone.local(2019, 11, 1),
          current_date: Time.zone.local(2019, 11, 1) + 1.month,
          expected: 1
        },
        {
          start_date: Time.zone.local(2019, 11, 1),
          current_date: Time.zone.local(2019, 11, 1) + 27.days,
          expected: 0
        },
        {
          start_date: Time.zone.local(2019, 11, 1),
          current_date: Time.zone.local(2019, 11, 1) + 2.months + 27.days,
          expected: 2
        },
        {
          start_date: Time.zone.local(2019, 2, 1),
          current_date: Time.zone.local(2019, 2, 1) + 29.days,
          expected: 1
        }
      ].each do |example|
        Timecop.freeze(example[:current_date]) do
          expect(subject.send(:full_months_since, example[:start_date])).to eq(example[:expected])
        end
      end
    end
  end

  def stub_informal_agreement(start_date:, frequency:, amount:, starting_balance:)
    agreement = create(:agreement,
                       tenancy_ref: tenancy_ref,
                       start_date: start_date,
                       frequency: frequency,
                       amount: amount,
                       starting_balance: starting_balance)

    create(:agreement_state,
           :live,
           agreement: agreement)

    agreement
  end
end
