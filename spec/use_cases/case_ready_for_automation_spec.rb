require 'rails_helper'

describe UseCases::CaseReadyForAutomation do
  subject { described_class.new }

  let(:tenancy_model) { Hackney::Income::Models::CasePriority }
  let(:patch_code_1) { 'ABC' }
  let(:patch_code_not_in_automation_list) { 'BAA' }

  context 'when fetching cases by patch' do
    before do
      tenancy_model.create!(
        tenancy_ref: Faker::Lorem.characters(8),
        balance: 40,
        patch_code: patch_code_1
      )

      tenancy_model.create!(
        tenancy_ref: Faker::Lorem.characters(8),
        balance: 40,
        patch_code: patch_code_not_in_automation_list
      )
    end

    it 'will return only the cases within a given patch' do
      expect(subject.execute(patch_code: patch_code_1)).to eq(true)
    end
  end

  context 'when the patch_code is not in the patch code automation list' do
    it 'will return false' do
      expect(subject.execute(patch_code: patch_code_not_in_automation_list)).to eq(false)
    end
  end
end
