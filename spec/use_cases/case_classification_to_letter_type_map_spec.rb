require 'rails_helper'

describe UseCases::CaseClassificationToLetterTypeMap do
  subject { described_class.new }

  context 'when checking a cases classification and letter for letter 1' do
    let(:letter_1) { 'income_collection_letter_1' }

    let(:case_priority_letter_1) {
      build(:case_priority,
            tenancy_ref: Faker::Number.number(4),
            classification: :send_letter_one)
    }

    it 'successfully checks the classification for letter 1' do
      expect(subject.execute(case_priority: case_priority_letter_1)).to eq(letter_1)
    end
  end

  context 'when checking a cases classification and letter for letter 2' do
    let(:letter_2) { 'income_collection_letter_2' }

    let(:case_priority_letter_2) {
      build(:case_priority,
            tenancy_ref: Faker::Number.number(4),
            classification: :send_letter_two)
    }

    it 'successfully checks the classification for letter 2' do
      expect(subject.execute(case_priority: case_priority_letter_2)).to eq(letter_2)
    end
  end
end
