module Hackney
  module Income
    class CreateEviction
      def execute(eviction_params:)
        params = {
          tenancy_ref: eviction_params[:tenancy_ref],
          date: eviction_params[:date]
        }

        eviction = Hackney::Income::Models::Eviction.create!(params)
        eviction
      end
    end
  end
end
