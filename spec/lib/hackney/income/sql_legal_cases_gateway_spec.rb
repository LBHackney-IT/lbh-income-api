require 'rails_helper'

describe Hackney::Income::SqlLegalCasesGateway, universal: true do
  subject { described_class.new }

  after { truncate_uh_tables }

  let(:high_actions_above_stage_4) { %w[4RS 5RP 6RC 6RO 7RE] }

  let(:tenancy_ref_array) do
    [
      Faker::Lorem.characters(8),
      Faker::Lorem.characters(8),
      Faker::Lorem.characters(8),
      Faker::Lorem.characters(8),
      Faker::Lorem.characters(8)
    ]
  end

  let(:property_ref_array) do
    [
      Faker::Lorem.characters(4),
      Faker::Lorem.characters(4),
      Faker::Lorem.characters(4),
      Faker::Lorem.characters(4),
      Faker::Lorem.characters(4)
    ]
  end

  let(:patch_code) { Faker::Lorem.characters(3) }

  let(:patch_codes) do
    [
      Faker::Lorem.characters(3),
      Faker::Lorem.characters(3),
      Faker::Lorem.characters(3)
    ]
  end

  context 'given a patch, get all tenancies above stage 4' do
    before do
      create_uh_tenancy_agreement_with_property(tenancy_ref: 'not_a_legal_case', prop_ref: '1234', arr_patch: 'W01')
      high_actions_above_stage_4.each_with_index do |high_action, i|
        create_uh_tenancy_agreement_with_property(
          tenancy_ref: tenancy_ref_array[i],
          high_action: high_action,
          prop_ref: property_ref_array[i],
          arr_patch: patch_code
        )
      end
    end

    it 'should return the tenancy refs for that patch' do
      expect(subject.get_tenancies_for_legal_process_for_patch(patch: patch_code)).to match_array(tenancy_ref_array)
    end
  end

  context 'given a patch with no tenancies with a high_action above stage 4' do
    before do
      patch_codes.each_with_index do |patch_code, i|
        create_uh_tenancy_agreement_with_property(
          tenancy_ref: tenancy_ref_array[i],
          high_action: 'below_stage_4',
          prop_ref: property_ref_array[i],
          arr_patch: patch_code
        )
      end
    end

    it 'should return an empty array' do
      patch_codes.each do |patch_code|
        expect(subject.get_tenancies_for_legal_process_for_patch(patch: patch_code)).to eq([])
      end
    end
  end
end
