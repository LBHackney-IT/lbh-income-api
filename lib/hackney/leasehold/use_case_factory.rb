module Hackney
  module Leasehold
    class UseCaseFactory
      def universal_housing_gateway
        Hackney::Leasehold::UniversalHousingGateway.new
      end

      def stored_action_gateway
        Hackney::Leasehold::StoredActionGateway.new
      end

      def schedule_sync_actions
        Hackney::Leasehold::ScheduleSyncActions.new(
          universal_housing_gateway: universal_housing_gateway,
          background_job_gateway: income_background_job_gateway
        )
      end

      def income_background_job_gateway
        Hackney::Income::BackgroundJobGateway.new
      end

      def sync_action_attributes
        Hackney::Leasehold::SyncActionAttributes.new(
          universal_housing_gateway: universal_housing_gateway,
          stored_action_gateway: stored_action_gateway
        )
      end
    end
  end
end
