require 'rails_helper'

describe Hackney::IncomeCollection::Letter do
  let(:letter_params) do
    {
      tenancy_ref: Faker::Number.number(6),
      payment_ref: Faker::Number.number(8),
      total_collectable_arrears_balance: Faker::Number.number(3),
      title: Faker::Job.title,
      forename: Faker::Name.first_name,
      surname: Faker::Name.last_name,
      address_line1: 'Address 1',
      address_line2: 'Address 2',
      address_line3: address_line3,
      address_line4: address_line4,
      address_post_code: 'E1 1YE'
    }
  end
  let(:address_line3) { nil }
  let(:address_line4) { nil }

  let(:letter) { described_class.new(letter_params) }

  describe '#build_tenant_address' do
    let(:built_address) { letter.tenant_address }

    context 'with all address lines present' do
      let(:address_line3) { 'Address 3' }
      let(:address_line4) { 'Address 4' }

      it 'returns 5 lines' do
        expect(built_address.split(/(?<=<br>)/).size).to eq(5)
      end

      it 'contains 4 line breaks' do
        parts = built_address.split(/(?<=<br>)/)
        parts.select! { |part| part.include?('<br>') }

        expect(parts.size).to eq(4)
      end
    end

    context 'with missing address line 4' do
      let(:address_line3) { 'Address 3' }
      let(:address_line4) { nil }

      it 'returns 5 lines' do
        expect(built_address.split(/(?<=<br>)/).size).to eq(5)
      end

      it 'contains 4 line breaks' do
        parts = built_address.split(/(?<=<br>)/)
        parts.select! { |part| part.include?('<br>') }

        expect(parts.size).to eq(4)
      end
    end

    context 'with missing address line 4 and line 3' do
      let(:address_line3) { nil }
      let(:address_line4) { nil }

      it 'returns 5 lines' do
        expect(built_address.split(/(?<=<br>)/).size).to eq(5)
      end

      it 'contains 4 line breaks' do
        parts = built_address.split(/(?<=<br>)/)
        parts.select! { |part| part.include?('<br>') }

        expect(parts.size).to eq(4)
      end
    end
  end
end
