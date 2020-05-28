module Hackney
  module Income
    class TenancyClassification
      def initialize(case_priority, criteria, documents)
        @version1 = Hackney::Income::TenancyClassificationV1.new(
          case_priority,
          criteria,
          documents
        )
        @version2 = Hackney::Income::TenancyClassificationV2.new(
          case_priority,
          criteria,
          documents
        )
      end

      def execute
        version1_action = @version1.execute
        version2_action = @version2.execute

        if version1_action != version2_action
          Rails.logger.error("The action from TenancyClassificationV1 #{version1_action} does not match TenancyClassificationV2 #{version2_action}")
        end

        version1_action
      end
    end
  end
end
