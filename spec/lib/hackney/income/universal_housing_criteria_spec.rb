require 'rails_helper'

describe Hackney::Income::UniversalHousingCriteria, universal: true do
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

    let(:payment_ref) { Faker::Number.number(digits: 10).to_s }

    before {
      create_uh_tenancy_agreement(
        tenancy_ref: tenancy_ref,
        current_balance: current_balance,
        nosp_notice_served_date: nosp_notice_served_date,
        nosp_notice_expiry_date: nosp_notice_expiry_date,
        courtdate: courtdate,
        court_outcome: court_outcome,
        eviction_date: eviction_date,
        u_saff_rentacc: payment_ref,
        rent: 5,
        service: 4.5,
        other_charge: 0.5
      )
    }

    it { is_expected.to be_instance_of(described_class) }

    describe '#balance' do
      subject { criteria.balance }

      it 'returns the current balance of a tenancy' do
        expect(subject).to eq(current_balance)
      end
    end

    describe '#payment_ref' do
      subject { criteria.payment_ref }

      it 'returns the current balance of a tenancy' do
        expect(subject).to eq(payment_ref)
      end
    end

    describe '#weekly_rent' do
      subject { criteria.weekly_rent }

      it 'returns the weekly rent of a tenancy' do
        expect(subject).to eq(5)
      end
    end

    describe '#weekly_service' do
      subject { criteria.weekly_service }

      it 'returns the weekly service of a tenancy' do
        expect(subject).to eq(4.5)
      end
    end

    describe '#weekly_other_charge' do
      subject { criteria.weekly_other_charge }

      it 'returns the weekly other charge of a tenancy' do
        expect(subject).to eq(0.5)
      end
    end

    describe '#weekly_gross_rent' do
      subject { criteria.weekly_gross_rent }

      it 'returns the weekly gross rent of a tenancy' do
        expect(subject).to eq(10)
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

      let(:court_outcome) { Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE }

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

      let(:nosp_notice_served_date) { 2.days.ago }

      it 'returns the nosp expiry date' do
        expect(subject).to eq((2.days.ago + Hackney::Domain::Nosp::ACTIVE_TIME).to_date)
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

    describe '#collectable_arrears' do
      subject { criteria.collectable_arrears }

      let(:current_balance) { 1000 }

      context 'when the tenant has never paid' do
        it { is_expected.to eq(current_balance) }
      end

      context 'when rent was issued on monday and a payment was made on tuesday' do
        before do
          create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RNT',  amount: 400, date: Date.today.beginning_of_week)
          create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RPY',  amount: -200, date: Date.today.beginning_of_week + 1.day)
        end

        it { is_expected.to eq(800) }
      end

      context 'when rent was issued last week on monday and a payment was made this week on tuesday' do
        before do
          create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RNT',  amount: 400, date: (Date.today - 7.days).beginning_of_week)
          create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RPY',  amount: -30, date: Date.today.beginning_of_week + 1.day)
        end

        it { is_expected.to eq(970) }
      end

      context 'when rent was issued on monday this week and a payment was made last week on monday' do
        before do
          create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RNT',  amount: 500, date: Date.today.beginning_of_week)
          create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RPY',  amount: -5, date: (Date.today - 7.days).beginning_of_week)
        end

        it { is_expected.to eq(500) }
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

      context 'when the tenant has a "first check" arrears agreement' do
        before do
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: '100',
            agreement_start_date: Time.zone.now
          )
        end

        it { is_expected.to be(true) }
      end

      context 'when the tenant has an active arrears agreement' do
        before do
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: '200',
            agreement_start_date: Time.zone.now
          )
        end

        it { is_expected.to be(true) }
      end

      context 'when the tenant has a breached arrears agreement' do
        before do
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: '300',
            agreement_start_date: Time.zone.now
          )
        end

        it { is_expected.to be(false) }
      end

      context 'when the tenant has a suspended arrears agreement' do
        before do
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: '400',
            agreement_start_date: Time.zone.now
          )
        end

        it { is_expected.to be(false) }
      end

      context 'when the tenant has a cancelled arrears agreement' do
        before do
          create_uh_arrears_agreement(
            tenancy_ref: tenancy_ref,
            status: '500',
            agreement_start_date: Time.zone.now
          )
        end

        it { is_expected.to be(false) }
      end
    end

    describe 'nosp_served?' do
      subject { criteria.nosp_served? }

      context 'when a tenant does not have a nosp' do
        let(:nosp_notice_served_date) { nil }

        it { is_expected.to be(false) }
      end

      context 'when a tenant had a nosp served recently' do
        let(:nosp_notice_served_date) { 1.day.ago }

        it { is_expected.to be(true) }
      end

      context 'when a tenant had a nosp served a year ago' do
        let(:nosp_notice_served_date) { 1.year.ago }

        it { is_expected.to be(true) }
      end

      context 'when a tenant had a nosp served over a year ago' do
        let(:nosp_notice_served_date) { 14.months.ago }

        it { is_expected.to be(true) }
      end
    end

    describe 'active_nosp?' do
      subject { criteria.active_nosp? }

      context 'when a tenant does not have a nosp' do
        let(:nosp_notice_served_date) { nil }

        it { is_expected.to be(false) }
      end

      context 'when a tenant had a nosp served recently' do
        let(:nosp_notice_served_date) { 2.days.ago }

        it { is_expected.to be(false) }
      end

      context 'when a tenant had a nosp served 4 months ago' do
        let(:nosp_notice_served_date) { 4.month.ago }

        it { is_expected.to be(true) }
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

    describe '#most_recent_agreement' do
      let(:start_date) { Date.new(2020, 1, 1) }

      context 'when a breached agreement exists' do
        before do
          create_uh_arrears_agreement(tenancy_ref: tenancy_ref, status: 300, agreement_start_date: start_date)
        end

        it 'can return the breach status' do
          expect(subject.most_recent_agreement[:breached]).to eq(true)
        end

        it 'can return the agreement start date' do
          expect(subject.most_recent_agreement[:start_date]).to eq(start_date)
        end
      end

      context 'when a first check agreement exists' do
        before do
          create_uh_arrears_agreement(tenancy_ref: tenancy_ref, status: 100, agreement_start_date: start_date)
        end

        it 'is not in breach' do
          expect(subject.most_recent_agreement[:breached]).to eq(false)
        end
      end

      context 'when there are two agreements' do
        before do
          create_uh_arrears_agreement(tenancy_ref: tenancy_ref, status: 300, agreement_start_date: 2.months.ago)
          create_uh_arrears_agreement(tenancy_ref: tenancy_ref, status: 200, agreement_start_date: 1.month.ago)
        end

        it 'returns the most recent agreement' do
          expect(subject.most_recent_agreement[:breached]).to eq(false)
        end
      end
    end

    describe '#nosp' do
      context 'when there is no NOSP served date' do
        let(:nosp_notice_served_date) { nil }

        it 'is not cooling off' do
          expect(criteria.nosp.in_cool_off_period?).to eq(false)
        end

        it 'is not valid' do
          expect(criteria.nosp.valid?).to eq(false)
        end

        it 'is not active' do
          expect(criteria.nosp.active?).to eq(false)
        end

        it 'has not been served' do
          expect(criteria.nosp.served?).to eq(false)
        end
      end

      context 'when there is a NOSP' do
        context 'with a served date that is in cooling off' do
          let(:nosp_notice_served_date) { 27.days.ago }

          it 'is cooling off' do
            expect(criteria.nosp.in_cool_off_period?).to eq(true)
          end

          it 'is valid' do
            expect(criteria.nosp.valid?).to eq(true)
          end

          it 'is not active' do
            expect(criteria.nosp.active?).to eq(false)
          end

          it 'has been served' do
            expect(criteria.nosp.served?).to eq(true)
          end
        end

        context 'with a served date that is over 3 months' do
          let(:nosp_notice_served_date) { (Hackney::Domain::Nosp::ACTIVE_TIME + 1.day).ago }

          it 'is not cooling off' do
            expect(criteria.nosp.in_cool_off_period?).to eq(false)
          end

          it 'is valid' do
            expect(criteria.nosp.valid?).to eq(true)
          end

          it 'is active' do
            expect(criteria.nosp.active?).to eq(true)
          end

          it 'has been served' do
            expect(criteria.nosp.served?).to eq(true)
          end
        end

        context 'with a served date that is over 16 months ago' do
          let(:nosp_notice_served_date) { 66.weeks.ago }

          it 'is not cooling off' do
            expect(criteria.nosp.in_cool_off_period?).to eq(false)
          end

          it 'is not valid' do
            expect(criteria.nosp.valid?).to eq(false)
          end

          it 'is not active' do
            expect(criteria.nosp.active?).to eq(false)
          end

          it 'has been served' do
            expect(criteria.nosp.served?).to eq(true)
          end
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
