require 'rails_helper'

describe Hackney::Leasehold::StoredActionGateway do
  let(:gateway) { described_class.new }

  let(:tenancy_model) { Hackney::IncomeCollection::Action }

  context 'when storing a tenancy' do
    subject(:store_action) do
      gateway.store_action(
          tenancy_ref: attributes.fetch(:tenancy_ref),
          attributes: attributes.fetch(:criteria)
      )
    end

    let(:attributes) do
      {
        tenancy_ref: Faker::Internet.slug,
        criteria: stubbed_criteria
      }
    end

    let(:stubbed_criteria) { Stubs::StubLeaseholdAttributes.new }

    context 'when the tenancy does not already exist' do
      let(:created_action) { tenancy_model.find_by(tenancy_ref: attributes.fetch(:tenancy_ref)) }

      it 'creates the tenancy' do
        store_action
        expect(created_action).to have_attributes(expected_serialised_tenancy(attributes))
      end

      it 'returns the tenancy' do
        expect(store_action).to eq(created_action)
      end
    end

    context 'when the tenancy already exists' do
      let!(:pre_existing_tenancy) do
        tenancy_model.create!(
          tenancy_ref: attributes.fetch(:tenancy_ref),
          balance: attributes.fetch(:criteria).balance,
          payment_ref: attributes.fetch(:criteria).payment_ref,
          patch_code: attributes.fetch(:criteria).patch_code,
          action_type: attributes.fetch(:criteria).tenure_type,
          service_area_type: Hackney::Leasehold::StoredActionGateway::SERVICE_AREA,
          metadata: {
            property_address: attributes.fetch(:criteria).property_address,
            lessee: attributes.fetch(:criteria).lessee,
            tenure_type: attributes.fetch(:criteria).tenure_type,
            direct_debit_status: attributes.fetch(:criteria).direct_debit_status,
            latest_letter: attributes.fetch(:criteria).latest_letter,
            latest_letter_date: attributes.fetch(:criteria).latest_letter_date
          }
        )
      end

      let(:stored_tenancy) { tenancy_model.find_by(tenancy_ref: attributes.fetch(:tenancy_ref)) }

      it 'updates the tenancy' do
        store_action
        expect(stored_tenancy).to have_attributes(expected_serialised_tenancy(attributes))
      end

      it 'does not create a new tenancy' do
        store_action
        expect(tenancy_model.count).to eq(1)
      end

      it 'returns the tenancy' do
        expect(store_action).to eq(pre_existing_tenancy)
      end
    end
  end

  def expected_serialised_tenancy(attributes)
    {
      tenancy_ref: attributes.fetch(:tenancy_ref),
      balance: attributes.fetch(:criteria).balance,
      payment_ref: attributes.fetch(:criteria).payment_ref,
      patch_code: attributes.fetch(:criteria).patch_code,
      action_type: attributes.fetch(:criteria).tenure_type,
      service_area_type: Hackney::Leasehold::StoredActionGateway::SERVICE_AREA,
      metadata: {
        property_address: attributes.fetch(:criteria).property_address,
        lessee: attributes.fetch(:criteria).lessee,
        tenure_type: attributes.fetch(:criteria).tenure_type,
        direct_debit_status: attributes.fetch(:criteria).direct_debit_status,
        latest_letter: attributes.fetch(:criteria).latest_letter,
        latest_letter_date: attributes.fetch(:criteria).latest_letter_date
      }
    }
  end
end
