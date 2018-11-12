module Hackney
  module Income
    class UseCaseFactory
      def view_my_cases
        Hackney::Income::ViewMyCases.new(
          tenancy_api_gateway: tenancy_api_gateway,
          stored_tenancies_gateway: stored_tenancies_gateway
        )
      end

      def sync_cases
        Hackney::Income::SyncCases.new(
          uh_tenancies_gateway: uh_tenancies_gateway,
          background_job_gateway: background_job_gateway
        )
      end

      def find_or_create_user
        Hackney::Income::FindOrCreateUser.new(users_gateway: users_gateway)
      end

      def set_tenancy_paused_status
        Hackney::Income::SetTenancyPausedStatus.new(gateway: sql_pause_tenancy_gateway)
      end

      def sync_case_priority
        Hackney::Income::SyncCasePriority.new(
          prioritisation_gateway: prioritisation_gateway,
          stored_tenancies_gateway: stored_tenancies_gateway,
          assign_tenancy_to_user: assign_tenancy_to_user
        )
      end

      def migrate_patch_to_lcw
        Hackney::Income::MigratePatchToLcw.new(
          legal_cases_gateway: legal_cases_gateway,
          user_assignment_gateway: user_assignment_gateway
        )
      end

      def assign_tenancy_to_user
        Hackney::Income::AssignTenancyToUser.new(user_assignment_gateway: user_assignment_gateway)
      end

      def show_tenancies_for_message_1
        Hackney::Income::ShowTenanciesForMessageOne.new(
          sql_tenancies_for_messages_gateway: sql_tenancies_for_messages_gateway
        )
      end

      private

      def legal_cases_gateway
        Hackney::Income::SqlLegalCasesGateway.new
      end

      def prioritisation_gateway
        Hackney::Income::UniversalHousingPrioritisationGateway.new
      end

      def sql_pause_tenancy_gateway
        Hackney::Income::SqlPauseTenancyGateway.new
      end

      def stored_tenancies_gateway
        Hackney::Income::StoredTenanciesGateway.new
      end

      def users_gateway
        Hackney::Income::SqlUsersGateway.new
      end

      def user_assignment_gateway
        Hackney::Income::SqlTenancyCaseGateway.new
      end

      def uh_tenancies_gateway
        Hackney::Income::UniversalHousingTenanciesGateway.new(
          restrict_patches: ENV.fetch('RESTRICT_PATCHES', false),
          patches: ENV.fetch('PERMITTED_PATCHES', '').split(',')
        )
      end

      def tenancy_api_gateway
        Hackney::Income::TenancyApiGateway.new(
          host: ENV['INCOME_COLLECTION_API_HOST'],
          key: ENV['INCOME_COLLECTION_API_KEY']
        )
      end

      def sql_tenancies_for_messages_gateway
        Hackney::Income::SqlTenanciesForMessagesGateway.new
      end

      def background_job_gateway
        Hackney::Income::BackgroundJobGateway.new
      end
    end
  end
end
