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

      def send_sms
        Hackney::Income::SendManualSms.new(
          notification_gateway: notifications_gateway,
          add_action_diary_usecase: add_action_diary
        )
      end

      def add_action_diary
        Hackney::Tenancy::AddActionDiaryEntry.new(
          action_diary_gateway: action_diary_gateway,
          users_gateway: users_gateway
        )
      end

      def send_email
        Hackney::Income::SendManualEmail.new(
          notification_gateway: notifications_gateway,
          add_action_diary_usecase: add_action_diary,
          sql_sent_messages_usecase: sql_sent_messages_usecase
        )
      end

      def get_templates
        Hackney::Income::GetTemplates.new(
          notification_gateway: notifications_gateway
        )
      end

      def get_sent_messages
        Hackney::Income::GetSentMessages.new(
          sql_gateway: sql_sent_messages_usecase,
          notifications_gateway: notifications_gateway
        )
      end

      def set_tenancy_paused_status
        Hackney::Income::SetTenancyPausedStatus.new(
          gateway: sql_pause_tenancy_gateway,
          add_action_diary_usecase: add_action_diary
        )
      end

      def get_tenancy_pause
        Hackney::Income::GetTenancyPause.new(
          gateway: sql_pause_tenancy_gateway
        )
      end

      def sync_case_priority
        ActiveSupport::Deprecation.warn(
          "SyncCasePriorityJob is deprecated - use external scheduler via 'rake income:sync:enqueue'"
        )
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

      def show_green_in_arrears
        Hackney::Income::ShowTenanciesForCriteriaGreenInArrears.new(
          sql_tenancies_for_messages_gateway: sql_tenancies_for_messages_gateway
        )
      end

      private

      def notifications_gateway
        Hackney::Income::GovNotifyGateway.new(
          sms_sender_id: ENV['GOV_NOTIFY_SENDER_ID'],
          api_key: ENV['GOV_NOTIFY_API_KEY'],
          send_live_communications: ENV['SEND_LIVE_COMMUNICATIONS'],
          test_phone_number: ENV['TEST_PHONE_NUMBER'],
          test_email_address:  ENV['TEST_EMAIL_ADDRESS']
        )
      end

      def legal_cases_gateway
        Hackney::Income::SqlLegalCasesGateway.new
      end

      def prioritisation_gateway
        Hackney::Income::UniversalHousingPrioritisationGateway.new
      end

      def sql_pause_tenancy_gateway
        Hackney::Income::SqlPauseTenancyGateway.new
      end

      def sql_sent_messages_usecase
        Hackney::Income::SqlSentMessages.new
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
        Hackney::Tenancy::Gateway::TenanciesGateway.new(
          host: ENV.fetch('TENANCY_API_HOST'),
          key: ENV.fetch('TENANCY_API_KEY')
        )
      end

      def sql_tenancies_for_messages_gateway
        Hackney::Income::SqlTenanciesForMessagesGateway.new
      end

      def action_diary_gateway
        Hackney::Tenancy::Gateway::ActionDiaryGateway.new(
          host: ENV.fetch('TENANCY_API_HOST'),
          api_key: ENV.fetch('TENANCY_API_KEY')
        )
      end

      def background_job_gateway
        Hackney::Income::BackgroundJobGateway.new
      end
    end
  end
end
