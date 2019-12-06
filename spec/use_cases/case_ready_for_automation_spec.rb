require 'rails_helper'

describe UseCases::CaseReadyForAutomation do
  let(:use_case) { described_class.new }

  let(:patch_code_1) { 'W02' }
  let(:patch_code_not_in_automation_list) { 'W03' }

  before do
    allow(use_case).to receive(:patch_codes_allowed_for_automation_env).and_return(patch_codes_env)
  end

  context 'when the patch code automation env is not defined' do
    let(:patch_codes_env) { nil }

    it 'is false' do
      expect(use_case.execute(patch_code: patch_code_1)).to eq(false)
    end
  end

  context 'when the patch code automation env is empty whitespace' do
    let(:patch_codes_env) { '' }

    it 'is false' do
      expect(use_case.execute(patch_code: patch_code_1)).to eq(false)
    end
  end

  context 'when the patch code automation env is defined' do
    let(:patch_codes_env) { 'W02,W04,W06' }

    it 'returns true if the patch code exists in the env' do
      expect(use_case.execute(patch_code: patch_code_1)).to eq(true)
    end

    it 'returns false if the patch code does not exist in the env' do
      expect(use_case.execute(patch_code: patch_code_not_in_automation_list)).to eq(false)
    end
  end

  context 'when the patch code env varibale has spacing' do
    let(:patch_codes_env) { 'W02, W04, W06' }

    it 'returns true if the patch code exists in the env' do
      expect(use_case.execute(patch_code: patch_code_1)).to eq(true)
    end
  end
end
