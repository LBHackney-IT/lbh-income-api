require 'rails_helper'

describe Hackney::Income::TenancyPrioritiser::TenancyClassification do
  subject { assign_classification.execute }

  let(:criteria) { Stubs::StubCriteria.new(attributes) }
  let(:assign_classification) { described_class.new(case_priority, criteria) }

  let(:attributes) do
    {
      weekly_rent: weekly_rent,
      balance: balance,
      nosp_served: nosp_served,
      last_communication_date: last_communication_date,
      last_communication_action: last_communication_action
    }
  end

  let(:case_priority) { build(:case_priority, is_paused_until: is_paused_until) }
  let(:is_paused_until) { nil }
  let(:weekly_rent) { 5.0 }
  let(:balance) { 5.00 }
  let(:nosp_served) { false }
  let(:last_communication_date) { 8.days.ago.to_date }
  let(:last_communication_action) { nil }

  context 'when there are no arrears' do
    context 'with difference balances' do
      balances = {
        in_credit: -3.00,
        under_five_pounds: 4.00,
        just_under_five_pounds: 4.99
      }

      balances.each do |key, balance|
        let(:balance) { balance }

        it "can classify a no action tenancy when the arrear level is #{key}" do
          expect(subject).to eq(:no_action)
        end
      end
    end

    context 'when the last action taken was over three months ago' do
      let(:last_communication_date) { 3.months.ago.to_date - 1.day }

      it 'can classify a no action tenancy' do
        expect(subject).to eq(:no_action)
      end
    end

    context 'when the last communication date was less than a week ago' do
      let(:last_communication_date) { 6.days.ago.to_date }

      it 'can classify a no action tenancy ' do
        expect(subject).to eq(:no_action)
      end
    end

    context 'when the the case has been paused' do
      let(:balance) { 15.00 }
      let(:nosp_served) { false }
      let(:last_communication_date) { 6.days.ago.to_date }
      let(:is_paused_until) { 7.days.from_now }

      it 'can classify a no action tenancy' do
        expect(subject).to eq(:no_action)
      end
    end

    context 'when a NOSP has been served' do
      let(:nosp_served) { true }

      it 'can classify a no action tenancy ' do
        expect(subject).to eq(:no_action)
      end
    end
  end

  context 'when no nosps have been served and the cases are not paused' do
    let(:nosp_served) { false }

    context 'when arrears level is greater than or equal to £5 and less than £10' do
      context 'with different balances' do
        balances = {
          five_pounds: 5.00,
          just_over_five_pounds: 5.01,
          over_five_pounds: 6.00,
          just_under_ten_pounds: 9.99
        }

        balances.each do |key, balance|
          let(:balance) { balance }

          it "can classify a send SMS tenancy when the arrear level is #{key}" do
            expect(subject).to eq(:send_first_SMS)
          end
        end
      end

      context 'with different last_communication_dates' do
        last_communication_dates = {
          seven_days_ago: 7.days.ago.to_date,
          eight_days_ago: 8.days.ago.to_date,
          within_three_months: 3.months.ago.to_date
        }

        last_communication_dates.each do |key, last_communication_date|
          let(:last_communication_date) { last_communication_date }

          it "can classify a send SMS tenancy when the last communication date is #{key}" do
            expect(subject).to eq(:send_first_SMS)
          end
        end
      end
    end

    context 'when the arrears are greater than or equal to £10 and less than one week rent' do
      context 'with different last communication actions' do
        last_communication_actions = {
          green_SMS_sent_auto: 'GAT',
          green_SMS_sent_manual: 'GMS'
        }

        let(:balance) { 11.00 }

        last_communication_actions.each do |key, last_communication_action|
          let(:last_communication_action) { last_communication_action }

          it "can classify to send letter one when arrears are more than £10 with a last communication action of #{key} " do
            expect(subject).to eq(:send_letter_one)
          end
        end
      end
    end

    context 'when the arrears are greater than or equal to one weeks rent and less than 3 week rent' do
      context 'with different last_communication_actions' do
        let(:balance) { weekly_rent }

        last_communication_actions = {
          letter_one_in_arrears_auto: 'IC1'
        }

        last_communication_actions.each do |key, last_communication_action|
          let(:last_communication_action) { last_communication_action }

          context "when the tenant has arreas of 1 week with a last communication action of #{key}" do
            it 'can classify to send letter two' do
              expect(subject).to eq(:send_letter_two)
            end
          end

          context "when the tenant is over 1 weeks in arrears with a last communication action of #{key}" do
            let(:last_communication_date) { 8.days.ago.to_date + 1.day }

            it 'can classify to send letter two' do
              expect(subject).to eq(:send_letter_two)
            end
          end

          context "when the tenant has just under 3 weeks with a last communication action of #{key}" do
            let(:balance) { weekly_rent * 3 - 1 }

            it 'can classify to send letter two' do
              expect(subject).to eq(:send_letter_two)
            end
          end
        end
      end
    end

    context 'when the arrears are greater than or equal to three weeks rent and less than 4 week rent' do
      last_communication_actions = {
        letter_two_in_arrears: 'IC2'
      }

      last_communication_actions.each do |key, last_communication_action|
        let(:last_communication_action) { last_communication_action }

        context "when the tenant has missed three weeks rent with a last communication action of #{key}" do
          let(:balance) { weekly_rent * 3 }

          it 'can classify to send a warning letter' do
            expect(subject).to eq(:send_warning_letter)
          end
        end

        context "when the tenant has missed just under 4 weeks rent with a last communication action of #{key}" do
          let(:balance) { weekly_rent * 4 - 1 }

          it 'can classify to send a warning letter' do
            expect(subject).to eq(:send_warning_letter)
          end
        end
      end
    end

    context 'when the arrears are greater than or equal 4 week rent' do
      last_communication_actions = {
        pre_nosp_warning_letter: 'not yet defined in UH' # this is a placeholder code defined in lib/hackney/tenancy/action_codes.rb
      }

      last_communication_actions.each do |key, last_communication_action|
        let(:last_communication_action) { last_communication_action }

        context "when the tenant has missed 4 weeks worth of rent with a last communication action of #{key}" do
          let(:balance) { weekly_rent * 4 }

          it 'can classify to send a NOSP' do
            expect(subject).to eq(:send_NOSP)
          end
        end

        context "when the tenant has missed over 4 weeks worth of rent with a last communication action of #{key}" do
          let(:balance) { weekly_rent * 4 + 1 }

          it 'can classify to send a NOSP' do
            expect(subject).to eq(:send_NOSP)
          end
        end
      end
    end
  end
end
