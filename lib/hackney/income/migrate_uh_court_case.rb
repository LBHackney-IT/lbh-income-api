module Hackney
  module Income
    class MigrateUhCourtCase
      def initialize(create_court_case:)
        @create_court_case = create_court_case
      end

      def migrate(criteria)
        @create_court_case.execute(map_criteria_to_court_case_params(criteria)) if should_migrate_criteria(criteria)
      end

      private

      def should_migrate_criteria(criteria)
        criteria.courtdate.present? || criteria.court_outcome.present?
      end

      def map_criteria_to_court_case_params(criteria)
        {
          court_date: criteria.courtdate,
          court_outcome: criteria.court_outcome
        }
      end
    end
  end
end
