require 'rails_helper'

describe Hackney::Income::DetectBreach do
  subject { described_class.new(tolerance_days: days_before_check) }

  let(:tenancy_ref) { Faker::Number.number(digits: 2).to_s }
  let(:days_before_check) { 5 }
  let(:start_date) { Time.zone.local(2019, 11, 1) }

  it 'allows a number of days before checking for breach' do
    start_date = Time.zone.local(2019, 11, 1)
    agreement = stub_informal_agreement(
      start_date: start_date,
      frequency: :monthly,
      amount: 500,
      starting_balance: 1000
    )

    date_within_tolerance = start_date + (days_before_check - 1).days

    Timecop.freeze(date_within_tolerance) do
      subject.execute(agreement: agreement)

      expect(agreement.current_state).to eq('live')
    end

    date_beyond_tolerance = start_date + days_before_check.days

    Timecop.freeze(date_beyond_tolerance) do
      subject.execute(agreement: agreement)

      expect(agreement.current_state).to eq('breached')
    end
  end

  context 'when the agreement has an inactive state' do
    let(:agreement) { build_stubbed(:agreement) }

    it 'returns false' do
      expect(subject.execute(agreement: agreement)).to be_falsy
    end
  end

  context 'when the agreement is not breached' do
    it 'returns false' do
      agreement = stub_informal_agreement(
        start_date: start_date,
        frequency: :monthly,
        amount: 500,
        starting_balance: 1000
      )

      Timecop.freeze(start_date) do
        expect(subject.execute(agreement: agreement)).to be_falsy
        expect(agreement.current_state).to eq('live')
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

      set_current_balance(80)

      one_month_later = start_date + days_before_check.days + 1.month
      one_day_before_next_cycle = one_month_later - 1.day

      Timecop.freeze(one_day_before_next_cycle) do
        subject.execute(agreement: agreement)

        expect(agreement.current_state).to eq('live')
      end

      Timecop.freeze(one_month_later) do
        subject.execute(agreement: agreement)

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

      set_current_balance(40)

      Timecop.freeze(one_day_before_next_cycle) do
        subject.execute(agreement: agreement)

        expect(agreement.current_state).to eq('live')
      end

      Timecop.freeze(three_weeks_later) do
        subject.execute(agreement: agreement)

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

      set_current_balance(80)

      two_weeks_later = start_date + days_before_check.days + 2.weeks
      one_day_before_next_cycle = two_weeks_later - 1.day

      Timecop.freeze(one_day_before_next_cycle) do
        subject.execute(agreement: agreement)

        expect(agreement.current_state).to eq('live')
      end

      Timecop.freeze(two_weeks_later) do
        subject.execute(agreement: agreement)

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

      set_current_balance(60)

      eight_weeks_later = start_date + days_before_check.days + 8.weeks
      one_day_before_next_cycle = eight_weeks_later - 1.day

      Timecop.freeze(one_day_before_next_cycle) do
        subject.execute(agreement: agreement)

        expect(agreement.current_state).to eq('live')
      end

      Timecop.freeze(eight_weeks_later) do
        subject.execute(agreement: agreement)

        expect(agreement.current_state).to eq('breached')
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
    create(:case_priority,
           tenancy_ref: tenancy_ref,
           balance: starting_balance)

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

  def set_current_balance(balance)
    Hackney::Income::Models::CasePriority.where(tenancy_ref: tenancy_ref).first.update(
      tenancy_ref: tenancy_ref,
      balance: balance
    )
  end
end
