require 'rails_helper'

describe Hackney::Income::SqlTenancyCaseGateway do
  subject { described_class.new }

  let(:gateway_model) { described_class::GatewayModel }

  context 'when persisting tenancies which do not exist in the database' do
    let(:tenancies) do
      random_size_array = (0..Faker::Number.between(1, 10)).to_a
      random_size_array.map { create_tenancy_model }
    end

    before do
      subject.persist(tenancies: tenancies)
    end

    it 'saves the tenancies in the database' do
      tenancies.each do |tenancy|
        expect(gateway_model).to exist(tenancy_ref: tenancy.tenancy_ref)
      end
    end
  end

  context 'when persisting a tenancy which already exists in the database' do
    let(:tenancy) { create_tenancy_model }
    let(:existing_tenancy_record) do
      gateway_model.create!(tenancy_ref: tenancy.tenancy_ref)
    end

    before do
      existing_tenancy_record
      subject.persist(tenancies: [tenancy])
    end

    it 'does not create a new record' do
      expect(gateway_model.count).to eq(1)
    end
  end

  def persist_new_tenancy
    tenancy = create_tenancy_model
    gateway_model.create!(tenancy_ref: tenancy.tenancy_ref)
  end
end
