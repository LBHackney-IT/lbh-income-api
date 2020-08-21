require 'rails_helper'

describe Hackney::Income::CreateAgreementMigration do
  subject { described_class.new }

  let(:legacy_id) { Faker::Number.number(digits: 5) }
  let(:agreement) { create(:agreement) }

  let(:new_agreement_migration_params) do
    {
      legacy_id: legacy_id,
      agreement_id: agreement.id
    }
  end

  it 'creates and returns a new agreement migration' do
    migration = subject.execute(agreement_migration_params: new_agreement_migration_params)
    latest_migration_id = Hackney::Income::Models::AgreementLegacyMigration.last.id
    expect(migration).to be_an_instance_of(Hackney::Income::Models::AgreementLegacyMigration)
    expect(migration.id).to eq(latest_migration_id)
    expect(migration.legacy_id).to eq(legacy_id)
    expect(migration.agreement_id).to eq(agreement.id)
  end
end
