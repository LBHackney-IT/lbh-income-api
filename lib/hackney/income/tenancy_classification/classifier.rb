module Hackney
  module Income
    module TenancyClassification
      class Classifier
        def initialize(case_priority, criteria, documents, contact_numbers)
          @case_priority = case_priority
          @criteria = criteria
          @documents = documents
          @contact_numbers = contact_numbers

          @version1_classifier = Hackney::Income::TenancyClassification::V1::Classifier.new(
            case_priority,
            criteria,
            documents
          )
          @version2_classifier = Hackney::Income::TenancyClassification::V2::Classifier.new(
            case_priority,
            criteria,
            documents,
            contact_numbers
          )
        end

        def execute
          version1_action = @version1_classifier.execute
          version2_action = @version2_classifier.execute

          if version1_action != version2_action
            Rails.logger.error(
              "CLASSIFIER: V1: #{version1_action} " \
               "V2: #{version2_action} " \
               "tenancy_ref: #{@criteria.tenancy_ref}"
            )
          else
            Rails.logger.info(
              "Classifier V1 & V2 Match for tenancy_ref: #{@criteria.tenancy_ref}"
            )
          end

          version1_action
        end
      end
    end
  end
end
