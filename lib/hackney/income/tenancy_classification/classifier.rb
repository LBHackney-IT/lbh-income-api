module Hackney
  module Income
    module TenancyClassification
      class Classifier
        def initialize(case_priority, criteria, documents)
          @case_priority = case_priority
          @criteria = criteria
          @documents = documents

          @classifier = Hackney::Income::TenancyClassification::V2::Classifier.new(
            case_priority,
            criteria,
            documents
          )
        end

        def execute
          action = @classifier.execute

          action
        end
      end
    end
  end
end
