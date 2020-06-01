module Hackney
  module Income
    module TenancyClassification
      class Classifier
        def initialize(case_priority, criteria, documents)
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

          Rails.logger.error("The action from V1 #{version1_action} does not match V2 #{version2_action}") if version1_action != version2_action

          version1_action
        end
      end
    end
  end
end
