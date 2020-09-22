module Hackney
  module Income
    class MigrateUhEviction
      def initialize(create_eviction:, view_evictions:)
        @create_eviction = create_eviction
        @view_evictions = view_evictions
      end

      def migrate(criteria)
        Rails.logger.debug { "Starting migration for UH eviction for tenancy ref #{criteria.tenancy_ref}" }

        unless criteria_contains_eviction(criteria)
          Rails.logger.debug { "No eviction data in criteria for tenancy ref #{criteria.tenancy_ref}" }
          return
        end

        uh_eviction = get_eviction_date(criteria.eviction_date)

        existing_evictions = @view_evictions.execute(tenancy_ref: criteria.tenancy_ref)

        if uh_eviction.present? && existing_evictions.empty?
          Rails.logger.debug { "Found no existing evictions for tenancy ref #{criteria.tenancy_ref}" }

          eviction_params = map_criteria_to_eviction_params(criteria).merge(tenancy_ref: criteria.tenancy_ref)

          @create_eviction.execute(eviction_params: eviction_params)
          return
        end

        return unless uh_eviction.present? && existing_evictions.last.eviction_date < uh_eviction

        Rails.logger.info { "UH eviction is older than existing MA date, adding newer eviction for tenancy ref #{criteria.tenancy_ref}" }
        eviction_params = map_criteria_to_eviction_params(criteria).merge(tenancy_ref: criteria.tenancy_ref)
        @create_eviction.execute(eviction_params: eviction_params)
      end

      private

      def criteria_contains_eviction(criteria)
        !get_eviction_date(criteria.eviction_date).nil?
      end

      def get_eviction_date(eviction_date)
        return nil if eviction_date == DateTime.parse('1900-01-01 00:00:00')
        eviction_date
      end

      def map_criteria_to_eviction_params(criteria)
        {
          date: get_eviction_date(criteria.eviction_date)
        }
      end
    end
  end
end
