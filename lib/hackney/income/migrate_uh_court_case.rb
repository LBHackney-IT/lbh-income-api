module Hackney
  module Income
    class MigrateUhCourtCase
      def initialize(create_court_case:)
        @create_court_case = create_court_case
      end

      def migrate(criteria)
        @create_court_case.execute(map_criteria_to_court_case_params(criteria)) if criteria.courtdate
      end

      private

      def map_criteria_to_court_case_params(criteria)
        {
          court_date: criteria.courtdate
        }
      end
    end
  end
end
