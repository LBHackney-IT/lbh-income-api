require 'rails_helper'

describe Hackney::Income::TenancyPrioritiser::UniversalHousingCriteria do
  subject(:criteria) { described_class.for_tenancy(tenancy_ref) }

  let(:tenancy_ref) { '000015/01' }
  let(:current_balance) { Faker::Number.decimal.to_f }

  let(:sql_client) do
    TinyTds::Client.new(
      username: ENV['UH_DATABASE_USERNAME'],
      password: ENV['UH_DATABASE_PASSWORD'],
      host: ENV['UH_DATABASE_HOST'],
      port: ENV['UH_DATABASE_PORT'],
      database: ENV['UH_DATABASE_NAME']
    )
  end

  before do
    create_tenancy_agreement(tenancy_ref: tenancy_ref, current_balance: current_balance)
  end

  after do
    sql_client.execute('TRUNCATE TABLE [dbo].[tenagree]').do
    sql_client.execute('TRUNCATE TABLE [dbo].[rtrans]').do
    sql_client.execute('TRUNCATE TABLE [dbo].[arag]').do
    sql_client.execute('TRUNCATE TABLE [dbo].[araction]').do
  end

  it { is_expected.to be_instance_of(described_class) }

  describe '#balance' do
    subject { criteria.balance }

    it 'should return the current balance of a tenancy' do
      expect(subject).to eq(current_balance)
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
        create_transaction(tenancy_ref: tenancy_ref, amount: 75.0, date: Date.today - 3.days)
        create_transaction(tenancy_ref: tenancy_ref, amount: 50.0, date: Date.today - 7.days)
      end

      it 'should return the difference between now and the first date it was in arrears' do
        expect(subject).to eq(7)
      end
    end

    context 'when the tenancy has been in arrears for two weeks' do
      let(:current_balance) { 100.00 }

      before do
        create_transaction(tenancy_ref: tenancy_ref, amount: 75.0, date: Date.today - 7.days)
        create_transaction(tenancy_ref: tenancy_ref, amount: 25.0, date: Date.today - 14.days)
      end

      it 'should return the difference between now and the first date it was in arrears' do
        expect(subject).to eq(14)
      end
    end

    context 'when the tenancy was previously not in arrears'

    context 'when the tenancy has always been in arrears' do
      let(:current_balance) { 100.00 }

      before do
        create_transaction(tenancy_ref: tenancy_ref, amount: 10.0, date: Date.today - 2.days)
        create_transaction(tenancy_ref: tenancy_ref, amount: 10.0, date: Date.today - 30.days)
      end

      it 'should return the first date' do
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
      before { create_transaction(tenancy_ref: tenancy_ref, type: 'RPY', date: Date.today - 2.days) }

      it { is_expected.to eq(2) }
    end

    context 'when the tenant paid five days ago, and rent was issued two days ago' do
      before do
        create_transaction(tenancy_ref: tenancy_ref, type: 'RNT', date: Date.today - 2.days)
        create_transaction(tenancy_ref: tenancy_ref, type: 'RPY', date: Date.today - 5.days)
      end

      it { is_expected.to eq(5) }
    end
  end

  describe '#active_agreement?' do
    subject { criteria.active_agreement? }

    context 'when the tenant has no arrears agreements' do
      it { is_expected.to be(false) }
    end

    context 'when the tenant has an active arrears agreement' do
      before { create_arrears_agreement(tenancy_ref: tenancy_ref, status: '200') }

      it { is_expected.to be(true) }
    end

    context 'when the tenant has a breached arrears agreement' do
      before { create_arrears_agreement(tenancy_ref: tenancy_ref, status: '300') }

      it { is_expected.to be(false) }
    end
  end

  describe '#number_of_broken_agreements' do
    subject { criteria.number_of_broken_agreements }

    context 'when the tenant has no arrears agreements' do
      it { is_expected.to be_zero }
    end

    context 'when the tenant has an active arrears agreement' do
      before { create_arrears_agreement(tenancy_ref: tenancy_ref, status: '200') }

      it { is_expected.to be_zero }
    end

    context 'when the tenant has a number of broken arrears agreement' do
      let(:broken_agreements_count) { Faker::Number.number(2).to_i }

      before do
        broken_agreements_count.times do
          create_arrears_agreement(tenancy_ref: tenancy_ref, status: '300')
        end
      end

      it 'should be equal the number of broken agreements' do
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
      before { create_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today) }

      it { is_expected.to be(true) }
    end

    context 'when a tenant had a nosp served a year ago' do
      before { create_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today - 1.year) }

      it { is_expected.to be(true) }
    end

    context 'when a tenant had a nosp served over a year ago' do
      before { create_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today - 1.year - 1.day) }

      it { is_expected.to be(false) }
    end
  end

  describe 'active_nosp?' do
    subject { criteria.active_nosp? }

    context 'when a tenant does not have a nosp' do
      it { is_expected.to be(false) }
    end

    context 'when a tenant had a nosp served recently' do
      before { create_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today) }

      it { is_expected.to be(true) }
    end

    context 'when a tenant had a nosp served a month ago' do
      before { create_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today - 20.days) }

      it { is_expected.to be(true) }
    end

    context 'when a tenant had a nosp served over a month ago' do
      before { create_action(tenancy_ref: tenancy_ref, code: 'NTS', date: Date.today - 32.days) }

      it { is_expected.to be(false) }
    end
  end

  describe '#payment_amount_delta' do
    subject { criteria.payment_amount_delta }

    context 'when a tenant has made no payments' do
      it { is_expected.to be(nil) }
    end

    context 'when a tenant has made one payment' do
      before { create_transaction(tenancy_ref: tenancy_ref, type: 'RPY') }

      it { is_expected.to be(nil) }
    end

    context 'when a tenant has made two payments' do
      before do
        create_transaction(tenancy_ref: tenancy_ref, type: 'RPY')
        create_transaction(tenancy_ref: tenancy_ref, type: 'RPY')
      end

      it { is_expected.to be(nil) }
    end

    context 'when a tenant has made three payments of fluctuating amounts' do
      before do
        create_transaction(tenancy_ref: tenancy_ref, amount: -25.0, date: Date.today - 1.day, type: 'RPY')
        create_transaction(tenancy_ref: tenancy_ref, amount: -75.0, date: Date.today - 2.days, type: 'RPY')
        create_transaction(tenancy_ref: tenancy_ref, amount: -75.0, date: Date.today - 3.days, type: 'RPY')
      end

      it 'should return the delta between payments' do
        expect(subject).to eq(50.0)
      end
    end

    context 'when a tenant has made three payments of the same amount' do
      before do
        create_transaction(tenancy_ref: tenancy_ref, amount: -50.0, date: Date.today - 1.day, type: 'RPY')
        create_transaction(tenancy_ref: tenancy_ref, amount: -50.0, date: Date.today - 2.days, type: 'RPY')
        create_transaction(tenancy_ref: tenancy_ref, amount: -50.0, date: Date.today - 3.days, type: 'RPY')
      end

      it 'should return the delta between payments' do
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
      before { create_transaction(tenancy_ref: tenancy_ref, type: 'RPY') }

      it { is_expected.to be(nil) }
    end

    context 'when a tenant has made two payments' do
      before do
        create_transaction(tenancy_ref: tenancy_ref, type: 'RPY')
        create_transaction(tenancy_ref: tenancy_ref, type: 'RPY')
      end

      it { is_expected.to be(nil) }
    end

    context 'when a tenant has made three payments on fluctuating days' do
      before do
        create_transaction(tenancy_ref: tenancy_ref, date: Date.today, type: 'RPY')
        create_transaction(tenancy_ref: tenancy_ref, date: Date.today - 15.days, type: 'RPY')
        create_transaction(tenancy_ref: tenancy_ref, date: Date.today - 25.days, type: 'RPY')
      end

      it 'should return the delta between payment dates' do
        expect(subject).to eq(5)
      end
    end

    context 'when a tenant has made three payments an equal amount of time apart' do
      before do
        create_transaction(tenancy_ref: tenancy_ref, date: Date.today - 10.days, type: 'RPY')
        create_transaction(tenancy_ref: tenancy_ref, date: Date.today - 20.days, type: 'RPY')
        create_transaction(tenancy_ref: tenancy_ref, date: Date.today - 30.days, type: 'RPY')
      end

      it 'should return the delta between payment dates' do
        expect(subject).to be_zero
      end
    end
  end

  describe '#broken_court_order?' do
    context 'when the tenant has no court ordered agreements' do
      it 'should be false' do
        expect(subject.broken_court_order?).to be(false)
      end
    end

    context 'when the tenant has an informal breached agreement' do
      before { create_arrears_agreement(tenancy_ref: tenancy_ref, status: '300') }

      it 'should be false' do
        expect(subject.broken_court_order?).to be(false)
      end
    end

    xcontext 'when the tenant has an breached court-ordered agreement' do
      before { create_arrears_agreement(tenancy_ref: tenancy_ref, status: '300') }

      it 'should be true' do
        expect(subject.broken_court_order?).to be(true)
      end
    end
  end

  def create_tenancy_agreement(tenancy_ref:, current_balance:)
    sql_client.execute("INSERT [dbo].[tenagree] (tag_ref, cur_bal) VALUES ('#{tenancy_ref}', #{current_balance})").do
  end

  def create_transaction(tenancy_ref:, amount: 0.0, date: Date.today, type: '')
    sql_client.execute("INSERT [dbo].[rtrans] (tag_ref, real_value, post_date, trans_type, batchid) VALUES ('#{tenancy_ref}', '#{amount}', '#{date}', '#{type}', #{rand(1..100000)})").do
  end

  def create_arrears_agreement(tenancy_ref:, status:)
    sql_client.execute("INSERT [dbo].[arag] (arag_ref, tag_ref, arag_status) VALUES ('#{Faker::IDNumber.valid}', '#{tenancy_ref}', '#{status}')").do
  end

  def create_action(tenancy_ref:, code:, date:)
    sql_client.execute("INSERT [dbo].[araction] (tag_ref, action_code, action_date) VALUES ('#{tenancy_ref}', '#{code}', '#{date}')").do
  end
end
