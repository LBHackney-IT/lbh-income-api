require 'rails_helper'

describe Hackney::Income::UniversalHousingPrioritisationGateway, universal: true do
  subject do
    described_class.new
  end

  context 'when given a tenancy ref' do
    let(:tenancy_ref) { Faker::Internet.slug }

    it 'returns the priority scores and criteria of that tenancy' do
      expect(subject.priorities_for_tenancy(tenancy_ref)).to include(
        criteria: an_instance_of(Hackney::Income::TenancyPrioritiser::UniversalHousingCriteria)
      )
    end

    it 'determines universal housing criteria' do
      expect(Hackney::Income::TenancyPrioritiser::UniversalHousingCriteria)
        .to receive(:for_tenancy)
        .with(an_instance_of(Sequel::TinyTDS::Database), tenancy_ref)

      subject.priorities_for_tenancy(tenancy_ref)
    end
  end
end
