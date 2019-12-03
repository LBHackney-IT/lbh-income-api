module UseCases
  class CaseClassificationToLetterTypeMap
    def execute(case_priority:)
      case case_priority.classification
      when 'send_letter_one'
        letter = 'income_collection_letter_1'
      when 'send_letter_two'
        letter = 'income_collection_letter_2'
      end
      letter
    end
  end
end
