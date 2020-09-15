module Hackney
  module Income
    class CreateEvictionDate
      def execute(eviction_date_params:)
        params = {
          tenancy_ref: eviction_date_params[:tenancy_ref],
          eviction_date: eviction_date_params[:eviction_date]
        }

        eviction_date = Hackney::Income::Models::EvictionDate.create!(params)
        eviction_date
      end
    end
  end
end
