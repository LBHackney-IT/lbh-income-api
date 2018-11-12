require 'rails_helper'

describe Hackney::Income::SqlTenanciesForMessagesGateway do
  subject { described_class.new }

  it 'returns an empty array when critira do not match' do
    expect(subject.get_tenancies_for_message_1).to eq([])
  end

  let(:case_worker) do
    Hackney::Income::Models::User.create!
  end

  context 'when there are red and green tennacys' do
    before do
      create_tenancy(band: 'green', user: case_worker) # TODO: enum band?
      create_tenancy(band: 'red', user: case_worker)
    end

    it 'returns only green tennacys' do
      expect(subject.get_tenancies_for_message_1.count).to eq(1)
      expect(subject.get_tenancies_for_message_1).to all(be_an(Hackney::Income::Models::Tenancy))
    end
  end

  context 'when there are diffrent ballences' do
    before do
      # LT 10
      create_tenancy(user: case_worker, balance: 9.99)
      create_tenancy(user: case_worker, balance: 9)
      # GTE 10
      create_tenancy(user: case_worker, balance: 10.00)
      create_tenancy(user: case_worker, balance: 11.00)
    end

    it 'returns only tennacys that are over £9.99' do
      expect(subject.get_tenancies_for_message_1.count).to eq(2)
      expect(subject.get_tenancies_for_message_1).to all(be_an(Hackney::Income::Models::Tenancy))
    end
  end

  context 'when there are diffrent days in arrears' do
    let(:num_tenancy_under_5_days) { Faker::Number.number(2).to_i }
    let(:num_tenancy_over_and_at_5_days) { Faker::Number.number(2).to_i }

    before do
      num_tenancy_under_5_days.times do
        create_tenancy(user: case_worker, days_in_arrears: Faker::Number.between(0, 4))
      end
      num_tenancy_over_and_at_5_days.times do
        create_tenancy(user: case_worker, days_in_arrears: Faker::Number.between(5, 1000))
      end
    end

    it 'returns only tennacys in arrers for more than 4 days' do
      expect(subject.get_tenancies_for_message_1.count).to eq(num_tenancy_over_and_at_5_days)
      expect(subject.get_tenancies_for_message_1).to all(be_an(Hackney::Income::Models::Tenancy))
    end
  end

  context 'when there are diffent active agrements' do
    let(:num_tenancy_active) { Faker::Number.number(2).to_i }
    let(:num_tenancy_inactive) { Faker::Number.number(2).to_i }

    before do
      num_tenancy_active.times do
        create_tenancy(user: case_worker, active_agreement: true)
      end
      num_tenancy_inactive.times do
        create_tenancy(user: case_worker, active_agreement: false)
      end
    end

    it 'returns only tennacys that do not have an active agrement' do
      expect(subject.get_tenancies_for_message_1.count).to eq(num_tenancy_inactive)
      expect(subject.get_tenancies_for_message_1).to all(be_an(Hackney::Income::Models::Tenancy))
    end
  end

  context 'when there are paused and unpaused tenancies' do
    let(:num_tenancy_paused) { Faker::Number.number(2).to_i }
    let(:num_tenancy_unpaused) { Faker::Number.number(2).to_i }

    before do
      num_tenancy_unpaused.times do |i|
        # is_paused_until field is nullable
        paused_value = i.even? ? Faker::Date.backward(23).to_s : nil
        create_tenancy(user: case_worker, is_paused_until: paused_value)
      end
      num_tenancy_paused.times do
        create_tenancy(user: case_worker, is_paused_until: Faker::Date.forward(23).to_s)
      end
    end

    it 'returns only unpaused tenancies' do
      expect(subject.get_tenancies_for_message_1.count).to eq(num_tenancy_unpaused)
      expect(subject.get_tenancies_for_message_1).to all(be_an(Hackney::Income::Models::Tenancy))
    end
  end
end

def create_tenancy(user:, band: 'green', balance: nil, days_in_arrears: nil, active_agreement: false, is_paused_until: nil)
  balance = Faker::Commerce.price(10..1000.0) if balance.nil?
  days_in_arrears = Faker::Number.between(5, 1000) if days_in_arrears.nil?
  Hackney::Income::Models::Tenancy.create!(
    priority_band: band,
    balance: balance,
    days_in_arrears: days_in_arrears,
    active_agreement: active_agreement,
    is_paused_until: is_paused_until
  )
end
