module Hackney
  module Income
    class ViewEvictionDates
      def execute(tenancy_ref:)
        requested_dates = Hackney::Income::Models::EvictionDate.where(tenancy_ref: tenancy_ref)

        return [] unless requested_dates.any?

        requested_dates
      end
    end
  end
end
