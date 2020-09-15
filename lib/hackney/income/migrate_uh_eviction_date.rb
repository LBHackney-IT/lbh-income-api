module Hackney
  module Income
    class MigrateUhEvictionDate
      def initialize(create_eviction_date:, view_eviction_dates:)
        @create_eviction_date = create_eviction_date
        @view_eviction_dates = view_eviction_dates
      end

      def migrate(criteria)
        Rails.logger.debug { "Starting migration for UH eviction date for tenancy ref #{criteria.tenancy_ref}" }

        unless criteria_contains_eviction_date(criteria)
          Rails.logger.debug { "No eviction date data in criteria for tenancy ref #{criteria.tenancy_ref}" }
          return
        end

        uh_eviction_date = get_eviction_date(criteria.eviction_date)

        existing_eviction_dates = @view_eviction_dates.execute(tenancy_ref: criteria.tenancy_ref)

        if uh_eviction_date.present? && existing_eviction_dates.empty?
          Rails.logger.debug { "Found no existing eviction dates for tenancy ref #{criteria.tenancy_ref}" }

          @create_eviction_date.execute(eviction_date: uh_eviction_date)
          return
        end

        return unless uh_eviction_date.present? && existing_eviction_dates.last.eviction_date < uh_eviction_date

        Rails.logger.info { "UH eviction date is older than existing MA date, adding newer eviction date for tenancy ref #{criteria.tenancy_ref}" }
        @create_eviction_date.execute(eviction_date: uh_eviction_date)
      end

      private

      def criteria_contains_eviction_date(criteria)
        !get_eviction_date(criteria.eviction_date).nil?
      end

      def get_eviction_date(eviction_date)
        return nil if eviction_date == DateTime.parse('1900-01-01 00:00:00')
        eviction_date
      end
    end
  end
end
