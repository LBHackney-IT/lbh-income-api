require 'rails_helper'

describe Hackney::Income::TenancyPrioritiser::UniversalHousingCriteria, universal: true do
  subject(:criteria) { described_class.for_tenancy(universal_housing_client, tenancy_ref) }

  context 'when there is a tenancy agreement' do
    let(:universal_housing_client) { Hackney::UniversalHousing::Client.connection }

    let(:tenancy_ref) { '000015/01' }

    let(:nosp_notice_served_date) { '2005-12-13 12:43:10' }

    let(:nosp_notice_expiry_date) { '2019-10-20 14:31:12' }

    let(:courtdate) { '2019-10-20 14:31:12' }

    let(:court_outcome) { nil }

    let(:eviction_date) { '2007-09-20 10:30:00' }

    let(:current_balance) { Faker::Number.decimal.to_f }

    before {
      create_uh_tenancy_agreement(
        tenancy_ref: tenancy_ref,
        current_balance: current_balance,
        nosp_notice_served_date: nosp_notice_served_date,
        nosp_notice_expiry_date: nosp_notice_expiry_date,
        courtdate: courtdate,
        court_outcome: court_outcome,
        eviction_date: eviction_date
      )
    }

    after { truncate_uh_tables }

    it { is_expected.to be_instance_of(described_class) }

    describe '#balance' do
      subject { criteria.balance }

      it 'returns the current balance of a tenancy' do
        expect(subject).to eq(current_balance)
      end
    end

    describe '#weekly_rent' do
      subject { criteria.weekly_rent }

      it 'returns the weekly rent of a tenancy' do
        expect(subject).to eq(5)
      end
    end

    describe '#courtdate' do
      subject { criteria.courtdate }

      it 'returns the courtdate' do
        expect(subject).to eq(courtdate.to_date)
      end
    end

    describe '#court_outcome' do
      subject { criteria.court_outcome }

      let(:court_outcome) { 'AGE' }

      it 'returns a court_outcome' do
        expect(subject).to eq(court_outcome)
      end
    end

    describe '#eviction_date' do
      subject { criteria.eviction_date }

      it 'returns an eviction date' do
        expect(subject).to eq(eviction_date.to_date)
      end

      context 'when UH returns no nosp expiry date (1900-01-01 00:00:00 +0000)' do
        before do
          truncate_uh_tables
          create_uh_tenancy_agreement(
            tenancy_ref: tenancy_ref,
            current_balance: current_balance
          )
        end

        it 'returns nil' do
          expect(subject).to eq(nil)
        end
      end
    end

    describe '#nosp_served_date' do
      subject { criteria.nosp_served_date }

      it 'returns the nosp served date' do
        expect(subject).to eq(nosp_notice_served_date.to_date)
      end

      context 'when UH returns no nosp expiry date (1900-01-01 00:00:00 +0000)' do
        before do
          truncate_uh_tables
          create_uh_tenancy_agreement(
            tenancy_ref: tenancy_ref,
            current_balance: current_balance
          )
        end

        it 'returns nil' do
          expect(subject).to eq(nil)
        end
      end
    end

    describe '#nosp_expiry_date' do
      subject { criteria.nosp_expiry_date }

      it 'returns the nosp expiry date' do
        expect(subject).to eq(nosp_notice_expiry_date.to_date)
      end

      context 'when UH returns no nosp expiry date (1900-01-01 00:00:00 +0000)' do
        before do
          truncate_uh_tables
          create_uh_tenancy_agreement(
            tenancy_ref: tenancy_ref,
            current_balance: current_balance
          )
        end

        it 'returns nil' do
          expect(subject).to eq(nil)
        end
      end
    end

    describe '#days_in_arrears' do
      subject { criteria.days_in_arrears }

      context 'when the tenancy is not in arrears' do
        let(:current_balance) { -50.00 }

        it { is_expected.to be_zero }
      end

      context 'when the tenancy has paid off their balance perfectly' do
        let(:current_balance) { 0.0 }

        it { is_expected.to be_zero }
      end

      context 'when the tenancy has been in arrears for a week' do
        let(:current_balance) { 100.00 }

        before do
          create_uh_transaction(tenancy_ref: tenancy_ref, amount: 75.0, date: Date.today - 3.days)
          create_uh_transaction(tenancy_ref: tenancy_ref, amount: 50.0, date: Date.today - 7.days)
        end

        it 'returns the difference between now and the first date it was in arrears' do
          expect(subject).to eq(7)
        end
      end

      context 'when the tenancy has been in arrears for two weeks' do
        let(:current_balance) { 100.00 }

        before do
          create_uh_transaction(tenancy_ref: tenancy_ref, amount: 75.0, date: Date.today - 7.days)
          create_uh_transaction(tenancy_ref: tenancy_ref, amount: 25.0, date: Date.today - 14.days)
        end

        it 'returns the difference between now and the first date it was in arrears' do
          expect(subject).to eq(14)
        end
      end

      context 'when the tenancy was previously not in arrears'

      context 'when the tenancy has always been in arrears' do
        let(:current_balance) { 100.00 }

        before do
          create_uh_transaction(tenancy_ref: tenancy_ref, amount: 10.0, date: Date.today - 2.days)
          create_uh_transaction(tenancy_ref: tenancy_ref, amount: 10.0, date: Date.today - 30.days)
        end

        it 'returns the first date' do
          expect(subject).to eq(30)
        end
      end
    end

    describe '#days_since_last_payment' do
      subject { criteria.days_since_last_payment }

      context 'when the tenant has never paid' do
        it { is_expected.to be_nil }
      end

      context 'when the tenant paid two days ago' do
        before { create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RPY', date: Date.today - 2.days) }

        it { is_expected.to eq(2) }
      end

      context 'when the tenant paid five days ago, and rent was issued two days ago' do
        before do
          create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RNT', date: Date.today - 2.days)
          create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RPY', date: Date.today - 5.days)
        end

        it { is_expected.to eq(5) }
      end
    end

    describe '#last_communciation_action' do
      subject { criteria.last_communication_action }

      context 'when the tenant has not been contacted' do
        it { is_expected.to be_nil }
      end

      context 'when in communication with the tenant' do
        before {
          create_uh_action(tenancy_ref: tenancy_ref, code: 'MML', date: Date.today)
          create_uh_action(tenancy_ref: tenancy_ref, code: 'S0A', date: Date.today - 2.days)
        }

        it 'return the latest communication code' do
          expect(subject).to eq('MML')
        end
      end

      context 'when an action code is not a communication action code' do
        before {
          create_uh_action(tenancy_ref: tenancy_ref, code: 'RBA', date: Date.today)
        }

        it { is_expected.to be_nil }
      end

      context 'with Stage 1 and Stage 2 letters' do
        let(:comment) { '' }

        before do
          create_uh_action(
            tenancy_ref: tenancy_ref,
            code: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1_UH,
            date: 14.days.ago
          )
          create_uh_action(
            tenancy_ref: tenancy_ref,
            code: Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH,
            date: Date.today,
            comment: comment
          )
        end

        context 'when Letter 2 has been sent' do
          let(:comment) { '    Policy Generated.    ' }

          it 'returns the Letter 2 action' do
            expect(subject).to eq(Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_2_UH)
          end
        end

        context 'when Letter 2 has been suggested' do
          let(:comment) { '     Suggested Action.    ' }

          it 'returns the Letter 1 action' do
            expect(subject).to eq(Hackney::Tenancy::ActionCodes::INCOME_COLLECTION_LETTER_1_UH)
          end
        end
      end
    end

    describe '#build_last_communication_sql_query' do
      it 'contains a Case Insensitive flag' do
        expect(
          described_class.build_last_communication_sql_query(column: 'action_code')
        ).to match(/collate SQL_Latin1_General_CP1_CI_AS LIKE/)
      end
    end

    describe '#last_communciation_date' do
      subject { criteria.last_communication_date }

      context 'when the tenant has not been contacted' do
        it { is_expected.to be_nil }
      end

      context 'when in communication with the tenant' do
        before {
          create_uh_action(tenancy_ref: tenancy_ref, code: 'S0A', date: Date.yesterday)
          create_uh_action(tenancy_ref: tenancy_ref, code: 'MML', date: Date.today)
        }

        it 'return the latest communication date' do
          expect(subject).to eq(Date.today)
        end
      end
    end

    describe '#active_agreement?' do
      subject { criteria.active_agreement? }

      context 'when the tenant has no arrears agreements' do
        it { is_expected.to be(false) }
      end

      context 'when the tenant has an active arrears agreement' do
        before { create_uh_arrears_agreement(tenancy_ref: tenancy_ref, status: '200') }

        it { is_expected.to be(true) }
      end

      context 'when the tenant has a breached arrears agreement' do
        before { create_uh_arrears_agreement(tenancy_ref: tenancy_ref, status: '300') }

        it { is_expected.to be(false) }
      end
    end

    describe '#number_of_broken_agreements' do
      subject { criteria.number_of_broken_agreements }

      context 'when the tenant has no arrears agreements' do
        it { is_expected.to be_zero }
      end

      context 'when the tenant has an active arrears agreement' do
        before { create_uh_arrears_agreement(tenancy_ref: tenancy_ref, status: '200') }

        it { is_expected.to be_zero }
      end

      context 'when the tenant has a number of broken arrears agreement' do
        let(:broken_agreements_count) { Faker::Number.number(2).to_i }

        before do
          broken_agreements_count.times do
            create_uh_arrears_agreement(tenancy_ref: tenancy_ref, status: '300')
          end
        end

        it 'is equal the number of broken agreements' do
          expect(subject).to eq(broken_agreements_count)
        end
      end
    end

    describe 'nosp_served?' do
      subject { criteria.nosp_served? }

      context 'when a tenant does not have a nosp' do
        it { is_expected.to be(false) }
      end

      context 'when a tenant had a nosp served recently' do
        before { create_uh_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today) }

        it { is_expected.to be(true) }
      end

      context 'when a tenant had a nosp served a year ago' do
        before { create_uh_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today - 1.year) }

        it { is_expected.to be(true) }
      end

      context 'when a tenant had a nosp served over a year ago' do
        before { create_uh_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today - 1.year - 1.day) }

        it { is_expected.to be(false) }
      end
    end

    describe 'active_nosp?' do
      subject { criteria.active_nosp? }

      context 'when a tenant does not have a nosp' do
        it { is_expected.to be(false) }
      end

      context 'when a tenant had a nosp served recently' do
        before { create_uh_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today) }

        it { is_expected.to be(true) }
      end

      context 'when a tenant had a nosp served a month ago' do
        before { create_uh_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today - 20.days) }

        it { is_expected.to be(true) }
      end

      context 'when a tenant had a nosp served over a month ago' do
        before { create_uh_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today - 32.days) }

        it { is_expected.to be(false) }
      end
    end

    describe '#broken_court_order?' do
      context 'when the tenant has no court ordered agreements' do
        it 'is false' do
          expect(subject.broken_court_order?).to be(false)
        end
      end

      context 'when the tenant has an informal breached agreement' do
        before { create_uh_arrears_agreement(tenancy_ref: tenancy_ref, status: '300') }

        it 'is false' do
          expect(subject.broken_court_order?).to be(false)
        end
      end
    end

    describe '#patch_code' do
      let(:patch_tenancy_code) { '100000/11' }

      context 'with an existing property reference' do
        before do
          create_uh_tenancy_agreement_with_property(tenancy_ref: patch_tenancy_code, arr_patch: patch_code)
        end

        context 'with a patch code' do
          let(:patch_code) { 'E01' }

          it 'contains the correct patch code' do
            expect(criteria.patch_code).to eq(patch_code)
          end
        end

        context 'without a patch code' do
          let(:patch_code) { nil }

          it 'is nil' do
            expect(criteria.patch_code).to be_nil
          end
        end
      end

      context "with a property reference that doesn't resolve" do
        it 'is nil' do
          expect(criteria.patch_code).to be_nil
        end
      end
    end

    describe '#universal_credit' do
      let(:tenancy_ref) { '100000/14' }
      let(:universal_credit_code) { 'UCC' }
      let(:date) { Date.today }

      context 'when there is a action diary entry' do
        it 'returns the date of entry' do
          create_uh_action(tenancy_ref: tenancy_ref, code: universal_credit_code, date: date)
          expect(subject.universal_credit).to eq(date)
        end
      end

      it 'returns nil by default when an entry is not made' do
        expect(subject.universal_credit).to eq(nil)
      end
    end

    describe '#uc_rent_verification' do
      let(:tenancy_ref) { '100000/15' }
      let(:rent_verification_complete_code) { 'UC1' }
      let(:date) { Date.today }

      context 'when there is a action diary entry' do
        it 'returns the date of entry' do
          create_uh_action(tenancy_ref: tenancy_ref, code: rent_verification_complete_code, date: date)
          expect(subject.uc_rent_verification).to eq(date)
        end
      end

      it 'returns nil by default when an entry is not made' do
        expect(subject.uc_rent_verification).to eq(nil)
      end
    end

    describe '#uc_direct_payment_requested' do
      let(:tenancy_ref) { '100000/16' }
      let(:uc_direct_payment_requested_code) { 'UC2' }
      let(:date) { Date.today }

      context 'when there is a action diary entry' do
        it 'returns the date of entry' do
          create_uh_action(tenancy_ref: tenancy_ref, code: uc_direct_payment_requested_code, date: date)
          expect(subject.uc_direct_payment_requested).to eq(date)
        end
      end

      it 'returns nil by default when an entry is not made' do
        expect(subject.uc_rent_verification).to eq(nil)
      end
    end

    describe '#uc_direct_payment_recieved' do
      let(:tenancy_ref) { '100000/17' }
      let(:uc_direct_payment_recieved_code) { 'UC3' }
      let(:date) { Date.today }

      context 'when there is a action diary entry' do
        it 'returns the date of entry' do
          create_uh_action(tenancy_ref: tenancy_ref, code: uc_direct_payment_recieved_code, date: date)
          expect(subject.uc_direct_payment_received).to eq(date)
        end
      end

      it 'returns nil by default when an entry is not made' do
        expect(subject.uc_rent_verification).to eq(nil)
      end
    end

    describe '#latest_active_agreement_date' do
      let(:yesterday) { Date.yesterday }

      context 'when the tenant breaches their active arrears agreement' do
        before do
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: '200',
            agreement_start_date: 2.days.ago
          )
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: '200',
            agreement_start_date: yesterday
          )
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: '300',
            agreement_start_date: Date.today
          )
        end

        it 'can retrieve the latest date where the agreement was active' do
          expect(subject.latest_active_agreement_date).to eq(yesterday)
        end
      end
    end

    describe '#breach_agreement_date' do
      let(:today) { Date.today }

      context 'when there is no breach of agreement' do
        before do
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: '200',
            status_entry_date: 2.days.ago
          )
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: 'anything',
            status_entry_date: 2.days.ago
          )
        end

        it 'will not retrive a date' do
          expect(subject.breach_agreement_date).to eq(nil)
        end
      end

      context 'when there is a breach of agreement' do
        before do
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: '200',
            status_entry_date: Date.yesterday
          )
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: '300',
            status_entry_date: today
          )
        end

        it 'can retrieve the breach date' do
          expect(subject.breach_agreement_date).to eq(today)
        end
      end
    end

    describe '#expected_balance' do
      let(:expected_balance) { 30 }

      before { create_uh_arrears_agreement(tenancy_ref: tenancy_ref, status: 200, expected_balance: expected_balance) }

      context 'when there is an expected balance set in an agreement' do
        it 'can retrun the expected balance of the account' do
          expect(subject.expected_balance).to eq(expected_balance)
        end
      end
    end

    it 'has the same instance methods as the stub' do
      expect(criteria.methods).to match_array(Stubs::StubCriteria.new.methods)
    end
  end

  describe '#format_action_codes_for_sql' do
    let(:code_one) { 'AAC' }
    let(:code_two) { 'DDE' }
    let(:stubbed_codes) { [code_one, code_two] }

    it 'formats the list of codes' do
      stub_const('Hackney::Tenancy::ActionCodes::FOR_UH_CRITERIA_SQL', stubbed_codes)

      expect(described_class.format_action_codes_for_sql).to eq("('#{code_one}'), ('#{code_two}')")
    end
  end

  describe '#build_sql' do
    let(:dummy_string) { "('SOME_STRING')" }

    it 'contains a correct list of Actions Codes' do
      expect(described_class).to receive(:format_action_codes_for_sql).and_return(dummy_string)

      expect(described_class.build_sql).to include(dummy_string)
    end
  end
end
