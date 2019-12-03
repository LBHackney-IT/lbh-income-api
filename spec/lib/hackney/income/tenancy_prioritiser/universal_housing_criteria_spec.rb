require 'rails_helper'

describe Hackney::Income::TenancyPrioritiser::UniversalHousingCriteria, universal: true do
  subject(:criteria) { described_class.for_tenancy(universal_housing_client, tenancy_ref) }

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

  describe '#payment_amount_delta' do
    subject { criteria.payment_amount_delta }

    context 'when a tenant has made no payments' do
      it { is_expected.to be(nil) }
    end

    context 'when a tenant has made one payment' do
      before { create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RPY') }

      it { is_expected.to be(nil) }
    end

    context 'when a tenant has made two payments' do
      before do
        create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RPY')
        create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RPY')
      end

      it { is_expected.to be(nil) }
    end

    context 'when a tenant has made three payments of fluctuating amounts' do
      before do
        create_uh_transaction(tenancy_ref: tenancy_ref, amount: -25.0, date: Date.today - 1.day, type: 'RPY')
        create_uh_transaction(tenancy_ref: tenancy_ref, amount: -75.0, date: Date.today - 2.days, type: 'RPY')
        create_uh_transaction(tenancy_ref: tenancy_ref, amount: -75.0, date: Date.today - 3.days, type: 'RPY')
      end

      it 'returns the delta between payments' do
        expect(subject).to eq(50.0)
      end
    end

    context 'when a tenant has made three payments of the same amount' do
      before do
        create_uh_transaction(tenancy_ref: tenancy_ref, amount: -50.0, date: Date.today - 1.day, type: 'RPY')
        create_uh_transaction(tenancy_ref: tenancy_ref, amount: -50.0, date: Date.today - 2.days, type: 'RPY')
        create_uh_transaction(tenancy_ref: tenancy_ref, amount: -50.0, date: Date.today - 3.days, type: 'RPY')
      end

      it 'returns the delta between payments' do
        expect(subject).to eq(0.0)
      end
    end
  end

  describe '#payment_date_delta' do
    subject { criteria.payment_date_delta }

    context 'when a tenant has made no payments' do
      it { is_expected.to be(nil) }
    end

    context 'when a tenant has made one payment' do
      before { create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RPY') }

      it { is_expected.to be(nil) }
    end

    context 'when a tenant has made two payments' do
      before do
        create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RPY')
        create_uh_transaction(tenancy_ref: tenancy_ref, type: 'RPY')
      end

      it { is_expected.to be(nil) }
    end

    context 'when a tenant has made three payments on fluctuating days' do
      before do
        create_uh_transaction(tenancy_ref: tenancy_ref, date: Date.today, type: 'RPY')
        create_uh_transaction(tenancy_ref: tenancy_ref, date: Date.today - 15.days, type: 'RPY')
        create_uh_transaction(tenancy_ref: tenancy_ref, date: Date.today - 25.days, type: 'RPY')
      end

      it 'returns the delta between payment dates' do
        expect(subject).to eq(5)
      end
    end

    context 'when a tenant has made three payments an equal amount of time apart' do
      before do
        create_uh_transaction(tenancy_ref: tenancy_ref, date: Date.today - 10.days, type: 'RPY')
        create_uh_transaction(tenancy_ref: tenancy_ref, date: Date.today - 20.days, type: 'RPY')
        create_uh_transaction(tenancy_ref: tenancy_ref, date: Date.today - 30.days, type: 'RPY')
      end

      it 'returns the delta between payment dates' do
        expect(subject).to be_zero
      end
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

  it 'has the same methods as the stub' do
    expect(criteria.methods).to match_array(Stubs::StubCriteria.new.methods)
  end
end
