require 'rails_helper'

describe UseCases::FetchCasesByPatch do
  subject { described_class.new }

  let(:tenancy_model) { Hackney::Income::Models::CasePriority }

  context 'when fetching cases by patch' do
    let(:patch_code_1) { ENV.fetch('PATCH_CODE') }
    let(:patch_code_2) { 'E02' }

    before do
      5.times do
        tenancy_model.create!(
          tenancy_ref: Faker::Lorem.characters(8),
          balance: 40,
          patch_code: patch_code_1
        )
      end

      2.times do
        tenancy_model.create!(
          tenancy_ref: Faker::Lorem.characters(8),
          balance: 40,
          patch_code: patch_code_2
        )
      end
    end

    it 'will return only the cases within a given patch' do
      expect(subject.execute.count).to eq(5)
    end
  end

  context 'when no patch is given' do
    it 'will raise an error' do

    end
  end
end
