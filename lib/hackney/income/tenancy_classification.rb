module Hackney
  module Income
    class TenancyClassification
      def initialize(case_priority, criteria, documents)
        @version1 = Hackney::Income::TenancyClassificationV1.new(
          case_priority,
          criteria,
          documents
        )
      end

      def execute
        @version1.execute
      end
    end
  end
end
