module UseCases
  class CheckCaseClassificationAndLetter
    def execute(case_priority:)
      if case_priority[:classification] == 'send_letter_one'
        letter = 'income_collection_letter_1'
      elsif case_priority[:classification] == 'send_letter_two'
        letter = 'income_collection_letter_2'
      end
    end
  end
end
