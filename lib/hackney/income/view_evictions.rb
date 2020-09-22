module Hackney
  module Income
    class ViewEvictions
      def execute(tenancy_ref:)
        requested_evictions = Hackney::Income::Models::Eviction.where(tenancy_ref: tenancy_ref)

        return [] unless requested_evictions.any?

        requested_evictions
      end
    end
  end
end
