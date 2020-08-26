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

          court_case_params = map_criteria_to_court_case_params(criteria).merge(tenancy_ref: criteria.tenancy_ref)

          # We are not syncing terms and disrepair_counter_claim but we validating presence of these if an outcome can have terms
          # will set these to false by default when syncing old data
          court_case_params = court_case_params.merge(terms: false, disrepair_counter_claim: false) if can_have_terms?(court_case_params)

          @create_court_case.execute(court_case_params: court_case_params)

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
          Rails.logger.debug { 'UH Criteria does not contain any new information' }
          return
        end

        @update_court_case.execute(id: existing_court_case.id, **court_case_params)
      end

      private

      def court_case_missing_detail(court_case)
        court_case.court_date.blank? || court_case.court_outcome.blank?
      end

      def criteria_contains_court_data(criteria)
        !get_courtdate(criteria.courtdate).nil? || !map_court_outcome(criteria.court_outcome).nil?
      end

      def map_criteria_to_court_case_params(criteria)
        {
          court_date: get_courtdate(criteria.courtdate),
          court_outcome: map_court_outcome(criteria.court_outcome)
        }
      end

      def get_courtdate(courtdate)
        return nil if courtdate == DateTime.parse('1900-01-01 00:00:00')

        courtdate
      end

      def map_court_outcome(outcome)
        return nil if outcome.nil? || outcome.strip.empty?

        case outcome.strip
        when Hackney::Tenancy::CourtOutcomeCodes::SUSPENDED_POSSESSION
          Hackney::Tenancy::UpdatedCourtOutcomeCodes::SUSPENSION_ON_TERMS
        when Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_ON_TERMS
          Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_ON_TERMS
        when Hackney::Tenancy::UpdatedCourtOutcomeCodes::STRUCK_OUT
          Hackney::Tenancy::UpdatedCourtOutcomeCodes::STRUCK_OUT
        when Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH
          Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH
        when Hackney::Tenancy::CourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
          Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
        when Hackney::Tenancy::UpdatedCourtOutcomeCodes::WITHDRAWN_ON_THE_DAY
          Hackney::Tenancy::UpdatedCourtOutcomeCodes::WITHDRAWN_ON_THE_DAY
        when Hackney::Tenancy::CourtOutcomeCodes::ADJOURNED_GENERALLY
          Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_GENERALLY_WITH_PERMISSION_TO_RESTORE
        when Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_TO_ANOTHER_HEARING_DATE
          Hackney::Tenancy::UpdatedCourtOutcomeCodes::ADJOURNED_TO_ANOTHER_HEARING_DATE
        end
      end

      def can_have_terms?(court_case_params)
        Hackney::Income::Models::CourtCase.new(court_case_params).can_have_terms?
      end
    end
  end
end
