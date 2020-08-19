module Hackney
  module Income
    class MigrateUhCourtCase
      def initialize(create_court_case:, view_court_cases:, update_court_case:)
        @create_court_case = create_court_case
        @view_court_cases = view_court_cases
        @update_court_case = update_court_case
      end

      def migrate(criteria)

        Rails.logger.debug { "Starting migration for UH court case for tenancy ref #{criteria.tenancy_ref}" }

        unless criteria_contains_court_data(criteria)
          Rails.logger.debug { "No court case data in criteria for tenancy ref #{criteria.tenancy_ref}" }
          return
        end

        existing_court_cases = @view_court_cases.execute(tenancy_ref: criteria.tenancy_ref)
        if existing_court_cases.empty?
          Rails.logger.debug { "Found no existing court cases for tenancy ref #{criteria.tenancy_ref}" }
          @create_court_case.execute(tenancy_ref: criteria.tenancy_ref, **map_criteria_to_court_case_params(criteria))
          return
        end

        if existing_court_cases.count != 1
          Rails.logger.info { "Will not update multiple court cases for tenancy ref #{criteria.tenancy_ref}" }
          return
        end

        existing_court_case = existing_court_cases.first

        unless court_case_missing_detail(existing_court_case)
          Rails.logger.info { "Will not update existing complete court case for tenancy ref #{criteria.tenancy_ref}" }
          return
        end

        court_case_params = map_criteria_to_court_case_params(criteria)

        court_case_params[:court_date] = nil if existing_court_case.court_date.present?
        court_case_params[:court_outcome] = nil if existing_court_case.court_outcome.present?

        if court_case_params.compact.keys.empty?
          Rails.logger.debug { "UH Criteria does not contain any new information" }
          return
        end

        @update_court_case.execute(id: existing_court_case.id, **court_case_params)
      end

      private

      def court_case_missing_detail(court_case)
        court_case.court_date.blank? || court_case.court_outcome.blank?
      end

      def criteria_contains_court_data(criteria)
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
