module Hackney
  module Income
    class UseCaseFactory
      def view_my_cases
        Hackney::Income::DangerousViewMyCases.new(
          tenancy_api_gateway: tenancy_api_gateway,
          stored_tenancies_gateway: stored_tenancies_gateway
        )
      end

      def sync_cases
        Hackney::Income::DangerousSyncCases.new(
          uh_tenancies_gateway: uh_tenancies_gateway,
          background_job_gateway: background_job_gateway
        )
      end

      def find_or_create_user
        Hackney::Income::FindOrCreateUser.new(users_gateway: users_gateway)
      end

      def sync_case_priority
        Hackney::Income::SyncCasePriority.new(
          prioritisation_gateway: prioritisation_gateway,
          stored_tenancies_gateway: stored_tenancies_gateway
        )
      end

      private

      def prioritisation_gateway
        Hackney::Income::UniversalHousingPrioritisationGateway.new
      end

      def stored_tenancies_gateway
        Hackney::Income::StoredTenanciesGateway.new
      end

      def users_gateway
        Hackney::Income::SqlUsersGateway.new
      end

      def uh_tenancies_gateway
        Hackney::Income::UniversalHousingTenanciesGateway.new(
          restrict_patches: ENV.fetch('RESTRICT_PATCHES', false),
          patches: ENV.fetch('PERMITTED_PATCHES', [])
        )
      end

      def tenancy_api_gateway
        Hackney::Income::TenancyApiGateway.new(
          host: ENV['INCOME_COLLECTION_API_HOST'],
          key: ENV['INCOME_COLLECTION_API_KEY']
        )
      end

      def background_job_gateway
        Hackney::Income::BackgroundJobGateway.new
      end
    end
  end
end
