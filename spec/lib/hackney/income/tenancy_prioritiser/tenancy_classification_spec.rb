require 'rails_helper'

describe Hackney::Income::TenancyPrioritiser::TenancyClassification do
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
      payment_ref: Faker::Number.number(10)
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

  context 'when checking that Action Codes are used in UH Criteria SQL' do
    let(:action_codes) { Hackney::Tenancy::ActionCodes::FOR_UH_CRITERIA_SQL }
    let(:unused_action_codes_required_for_uh_criteria_sql) { result - action_codes }

    describe '#after_letter_one_actions' do
      let(:result) { assign_classification.send(:after_letter_one_actions) }

      it 'contains Letter 2 UH code that is used for an edge case in the UH Criteria SQL' do
        expect(unused_action_codes_required_for_uh_criteria_sql).to eq([Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH])
      end
    end

    describe '#valid_actions_for_letter_two_to_progress' do
      let(:result) { assign_classification.send(:valid_actions_for_letter_two_to_progress) }

      it 'contains action codes within the UH Criteria Codes' do
        expect(unused_action_codes_required_for_uh_criteria_sql).to be_empty
      end
    end

    describe '#valid_actions_for_nosp_to_progress' do
      let(:result) { assign_classification.send(:valid_actions_for_nosp_to_progress) }

      it 'contains Letter 2 UH code that is used for an edge case in the UH Criteria SQL' do
        expect(unused_action_codes_required_for_uh_criteria_sql).to eq([Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH])
      end
    end

    describe '#after_court_warning_letter_actions' do
      let(:result) { assign_classification.send(:after_court_warning_letter_actions) }

      it 'contains action codes within the UH Criteria Codes' do
        expect(unused_action_codes_required_for_uh_criteria_sql).to be_empty
      end
    end

    describe '#court_breach_letter_actions' do
      let(:result) { assign_classification.send(:court_breach_letter_actions) }

      it 'contains action codes within the UH Criteria Codes' do
        expect(result - action_codes).to be_empty
      end
    end

    describe '#valid_actions_for_court_breach_no_payment' do
      let(:result) { assign_classification.send(:valid_actions_for_court_breach_no_payment) }

      it 'contains action codes within the UH Criteria Codes' do
        expect(result - action_codes).to be_empty
      end
    end

    describe '#valid_actions_for_apply_for_court_date_to_progress' do
      let(:result) { assign_classification.send(:valid_actions_for_apply_for_court_date_to_progress) }

      it 'contains action codes within the UH Criteria Codes' do
        expect(unused_action_codes_required_for_uh_criteria_sql).to be_empty
      end
    end
  end
end
