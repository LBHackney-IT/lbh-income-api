require 'rails_helper'

describe Hackney::Income::TenancyClassification::Classifier do
  subject { assign_classification.execute }

  let(:criteria) { Stubs::StubCriteria.new(attributes) }
  let(:documents_related_to_case) { [] }
  let(:assign_classification) { described_class.new(case_priority, criteria, documents_related_to_case) }

  let(:attributes) do
    {
      weekly_rent: weekly_rent,
      balance: balance,
      nosp_served: nosp_served,
      last_communication_date: last_communication_date,
      last_communication_action: last_communication_action,
      eviction_date: eviction_date,
      payment_ref: Faker::Number.number(digits: 10),
      total_payment_amount_in_week: total_payment_amount_in_week
    }
  end

  let(:case_priority) { build(:case_priority, is_paused_until: is_paused_until) }
  let(:is_paused_until) { nil }
  let(:weekly_rent) { 5.0 }
  let(:balance) { 5.00 }
  let(:nosp_served) { false }
  let(:last_communication_date) { 8.days.ago.to_date }
  let(:last_communication_action) { nil }
  let(:eviction_date) { 6.days.ago.to_date }
  let(:total_payment_amount_in_week) { 0 }

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

    context 'when we sent a letter less than a week ago' do
      let(:last_communication_date) { 6.days.ago.to_date }
      let(:last_communication_action) { Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1 }

      it 'can classify a no action tenancy ' do
        expect(subject).to eq(:no_action)
      end

      context 'when the letter sent failed govnotify validation' do
        before do
          create(:document, status: 'validation-failed',
                            metadata: {
                              payment_ref: attributes[:payment_ref],
                              template: {
                                path: 'lib/hackney/pdf/templates/income/income_collection_letter_1.erb',
                                name: 'Income collection letter 1',
                                id: 'income_collection_letter_1'
                              }
                            }.to_json)
        end

        let(:documents_related_to_case) { Hackney::Cloud::Document.by_payment_ref(attributes[:payment_ref]) }

        it 'can classify a review failed letter tenancy' do
          expect(subject).to eq(:review_failed_letter)
        end
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

  describe '#calculated_grace_amount' do
    it 'uses #weekly_gross_rent' do
      expect(criteria).to receive(:weekly_gross_rent).and_return(0)

      assign_classification.send(:calculated_grace_amount)
    end

    it 'uses #total_payment_amount_in_week' do
      expect(criteria).to receive(:total_payment_amount_in_week).and_return(0)

      assign_classification.send(:calculated_grace_amount)
    end

    context 'when there is no payment in the week' do
      it 'returns the total weekly gross rent' do
        calculated_grace_amount = assign_classification.send(:calculated_grace_amount)
        expect(calculated_grace_amount).to eq(weekly_rent)
      end
    end

    context 'when there is a payment in the week' do
      context 'with the total payment amount not being above the weekly rent' do
        let(:total_payment_amount_in_week) { -2 }

        it 'returns not the total weekly rent' do
          calculated_grace_amount = assign_classification.send(:calculated_grace_amount)
          expect(calculated_grace_amount).to eq(weekly_rent + total_payment_amount_in_week)
        end
      end

      context 'with the total payment amount equals the weekly rent' do
        let(:total_payment_amount_in_week) { -5 }

        it 'returns not the total weekly rent' do
          calculated_grace_amount = assign_classification.send(:calculated_grace_amount)
          expect(calculated_grace_amount).to eq(0)
        end
      end

      context 'with the total payment amount is more than the weekly rent' do
        let(:total_payment_amount_in_week) { -10 }

        it 'returns not the total weekly rent' do
          calculated_grace_amount = assign_classification.send(:calculated_grace_amount)
          expect(calculated_grace_amount).to eq(0)
        end
      end
    end
  end
end
