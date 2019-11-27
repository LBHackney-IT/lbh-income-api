require 'rails_helper'

describe UseCases::FetchCasesByPatch do
  subject { described_class.new }

  let(:tenancy_model) { Hackney::Income::Models::CasePriority }
  let(:patch_code_1) { 'ABC' }
  let(:patch_code_2) { 'XYZ' }
  let(:patch_code_not_in_patch_list) { 'BAA' }

  context 'when fetching cases by patch' do
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
      expect(subject.execute(patch_code: patch_code_1).count).to eq(5)
    end
  end

  context 'when no patch is given' do
    it 'will raise an error' do
      expect { subject.execute(patch_code: patch_code_not_in_patch_list) }.to raise_error(ArgumentError)
    end
  end
end
