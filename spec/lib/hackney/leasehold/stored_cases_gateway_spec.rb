require 'rails_helper'

describe Hackney::Leasehold::StoredCasesGateway do
  let(:gateway) { described_class.new }

  let(:tenancy_model) { Hackney::Leasehold::CaseAttributes }

  context 'when storing a tenancy' do
    subject(:store_case) do
      gateway.store_case(
        tenancy_ref: attributes.fetch(:tenancy_ref),
        criteria: attributes.fetch(:criteria)
      )
    end

    let(:attributes) do
      {
        tenancy_ref: Faker::Internet.slug,
        criteria: stubbed_criteria
      }
    end

    let(:stubbed_criteria) { Stubs::StubLeaseholdCriteria.new }

    context 'when the tenancy does not already exist' do
      let(:created_tenancy) { tenancy_model.find_by(tenancy_ref: attributes.fetch(:tenancy_ref)) }

      it 'creates the tenancy' do
        store_case
        expect(created_tenancy).to have_attributes(expected_serialised_tenancy(attributes))
      end

      it 'returns the tenancy' do
        expect(store_case).to eq(created_tenancy)
      end
    end

    context 'when the tenancy already exists' do
      let!(:pre_existing_tenancy) do
        tenancy_model.create!(
          tenancy_ref: attributes.fetch(:tenancy_ref),
          balance: attributes.fetch(:criteria).balance,
          payment_ref: attributes.fetch(:criteria).payment_ref,
          patch: attributes.fetch(:criteria).patch_code,
          property_address: attributes.fetch(:criteria).property_address,
          lessee: attributes.fetch(:criteria).lessee,
          tenure_type: attributes.fetch(:criteria).tenure_type,
          direct_debit_status: attributes.fetch(:criteria).direct_debit_status,
          latest_letter: attributes.fetch(:criteria).latest_letter,
          latest_letter_date: attributes.fetch(:criteria).latest_letter_date
        )
      end

      let(:stored_tenancy) { tenancy_model.find_by(tenancy_ref: attributes.fetch(:tenancy_ref)) }

      it 'updates the tenancy' do
        store_case
        expect(stored_tenancy).to have_attributes(expected_serialised_tenancy(attributes))
      end

      it 'does not create a new tenancy' do
        store_case
        expect(tenancy_model.count).to eq(1)
      end

      it 'returns the tenancy' do
        expect(store_case).to eq(pre_existing_tenancy)
      end
    end
  end

  def expected_serialised_tenancy(attributes)
    {
      tenancy_ref: attributes.fetch(:tenancy_ref),
      balance: attributes.fetch(:criteria).balance,
      payment_ref: attributes.fetch(:criteria).payment_ref,
      patch: attributes.fetch(:criteria).patch_code,
      property_address: attributes.fetch(:criteria).property_address,
      lessee: attributes.fetch(:criteria).lessee,
      tenure_type: attributes.fetch(:criteria).tenure_type,
      direct_debit_status: attributes.fetch(:criteria).direct_debit_status,
      latest_letter: attributes.fetch(:criteria).latest_letter,
      latest_letter_date: attributes.fetch(:criteria).latest_letter_date
    }
  end
end
