module Hackney
  module Income
    module TenancyClassification
      class Classifier
        def initialize(case_priority, criteria, documents)
          @case_priority = case_priority
          @criteria = criteria
          @documents = documents

          @version1_classifier = Hackney::Income::TenancyClassification::V1::Classifier.new(
            case_priority,
            criteria,
            documents
          )
          @version2_classifier = Hackney::Income::TenancyClassification::V2::Classifier.new(
            case_priority,
            criteria,
            documents
          )
        end

        def execute
          version1_action = @version1_classifier.execute
          version2_action = @version2_classifier.execute

          if version1_action != version2_action
            Rails.logger.error(
              "CLASSIFIER: V1: #{version1_action} " \
               "V2: #{version2_action} " \
               "Criteria: #{@criteria} " \
               "CasePriority: #{@case_priority} " \
               "Document Count: #{@documents.length}"
            )
          end

          version1_action
        end
      end
    end
  end
end
