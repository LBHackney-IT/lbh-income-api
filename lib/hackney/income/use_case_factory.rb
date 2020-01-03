module Hackney
  module Income
    class UseCaseFactory
      def view_cases
        Hackney::Income::ViewCases.new(
          tenancy_api_gateway: tenancy_api_gateway,
          stored_tenancies_gateway: stored_tenancies_gateway
        )
      end

      def schedule_sync_cases
        Hackney::Income::ScheduleSyncCases.new(
          uh_tenancies_gateway: uh_tenancies_gateway,
          background_job_gateway: background_job_gateway
        )
      end

      def schedule_green_in_arrears_message
        Hackney::Income::ScheduleGreenInArrearsMessage.new(
          matching_criteria_gateway: sql_tenancies_matching_criteria_gateway,
          background_job_gateway: background_job_gateway
        )
      end

      def add_action_diary
        Hackney::Tenancy::AddActionDiaryEntry.new(
          action_diary_gateway: action_diary_gateway
        )
      end

      def send_manual_sms
        Hackney::Notification::SendManualSms.new(
          notification_gateway: notifications_gateway,
          add_action_diary_usecase: add_action_diary
        )
      end

      def send_manual_email
        Hackney::Notification::SendManualEmail.new(
          notification_gateway: notifications_gateway,
          add_action_diary_usecase: add_action_diary
        )
      end

      def send_letter
        Hackney::Income::ProcessLetter.new(
          cloud_storage: cloud_storage
        )
      end

      def send_precompiled_letter
        Hackney::Notification::SendManualPrecompiledLetter.new(
          notification_gateway: notifications_gateway,
          add_action_diary_usecase: add_action_diary,
          leasehold_gateway: Hackney::Income::UniversalHousingLeaseholdGateway.new
        )
      end

      def send_precompiled_letter_to_gov_notify
        Hackney::Notification::SendPrecompiledLetter.new(
          notification_gateway: notifications_gateway
        )
      end

      def request_precompiled_letter_state
        document_store = Hackney::Cloud::Document
        Hackney::Notification::RequestPrecompiledLetterState.new(
          notification_gateway: notifications_gateway,
          add_action_diary_usecase: add_action_diary,
          document_store: document_store
        )
      end

      def enqueue_request_all_precompiled_letter_states
        enqueue_job = Hackney::Income::Jobs::RequestPrecompiledLetterStateJob
        document_store = Hackney::Cloud::Document

        Hackney::Notification::EnqueueRequestAllPrecompiledLetterStates.new(
          enqueue_job: enqueue_job,
          document_store: document_store
        )
      end

      def send_automated_sms
        Hackney::Notification::SendAutomatedSms.new(
          notification_gateway: notifications_gateway,
          background_job_gateway: background_job_gateway
        )
      end

      def send_automated_email
        Hackney::Notification::SendAutomatedEmail.new(
          notification_gateway: notifications_gateway,
          background_job_gateway: background_job_gateway
        )
      end

      def send_automated_message_to_tenancy
        Hackney::Notification::SendAutomatedMessageToTenancy.new(
          automated_sms_usecase: send_automated_sms,
          automated_email_usecase: send_automated_email,
          contacts_gateway: contacts_gateway
        )
      end

      def get_templates
        Hackney::Income::GetTemplates.new(
          notification_gateway: notifications_gateway
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

      def get_tenancy
        Hackney::Income::GetTenancy.new(
          gateway: Hackney::Income::SqlTenancyCaseGateway.new
        )
      end

      def add_action_diary_and_sync_case
        UseCases::AddActionDiaryAndSyncCase.new(
          sync_case_priority: sync_case_priority,
          add_action_diary: add_action_diary
        )
      end

      def automate_sending_letters
        UseCases::AutomateSendingLetters.new(
          case_ready_for_automation: case_ready_for_automation,
          case_classification_to_letter_type_map: case_classification_to_letter_type_map,
          generate_and_store_letter: generate_and_store_letter,
          send_letter_to_gov_notify: send_letter_to_gov_notify
        )
      end

      def send_letter_to_gov_notify
        Hackney::Income::Jobs::SendLetterToGovNotifyJob
      end

      def generate_and_store_letter
        UseCases::GenerateAndStoreLetter.new
      end

      def case_classification_to_letter_type_map
        UseCases::CaseClassificationToLetterTypeMap.new
      end

      def case_ready_for_automation
        UseCases::CaseReadyForAutomation.new
      end

      def sync_case_priority
        ActiveSupport::Deprecation.warn(
          "SyncCasePriorityJob is deprecated - use external scheduler via 'rake income:sync:enqueue'"
        )
        Hackney::Income::SyncCasePriority.new(
          automate_sending_letters: automate_sending_letters,
          prioritisation_gateway: prioritisation_gateway,
          stored_tenancies_gateway: stored_tenancies_gateway
        )
      end

      def get_failed_sms_messages
        Hackney::Notification::GetFailedSMSMessages.new(
          notification_gateway: notifications_gateway
        )
      end

      def uh_tenancies_gateway
        Hackney::Income::UniversalHousingTenanciesGateway.new
      end

      private

      def cloud_storage
        Hackney::Cloud::Storage.new(
          Rails.configuration.cloud_adapter,
          Hackney::Cloud::Document
        )
      end

      def notifications_gateway
        Hackney::Notification::GovNotifyGateway.new(
          sms_sender_id: Rails.configuration.x.gov_notify.sms_sender_id,
          api_key: Rails.configuration.x.gov_notify.api_key,
          send_live_communications: Rails.configuration.x.gov_notify.send_live,
          test_phone_number: Rails.configuration.x.gov_notify.test_phone_number,
          test_email_address: Rails.configuration.x.gov_notify.test_email_address
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

      def stored_tenancies_gateway
        Hackney::Income::StoredTenanciesGateway.new
      end

      def tenancy_api_gateway
        Hackney::Tenancy::Gateway::TenanciesGateway.new(
          host: ENV.fetch('TENANCY_API_HOST'),
          key: ENV.fetch('TENANCY_API_KEY')
        )
      end

      def contacts_gateway
        Hackney::Tenancy::Gateway::ContactsGateway.new(
          host: ENV.fetch('TENANCY_API_HOST'),
          api_key: ENV.fetch('TENANCY_API_KEY')
        )
      end

      def action_diary_gateway
        Hackney::Tenancy::Gateway::ActionDiaryGateway.new(
          host: ENV.fetch('TENANCY_API_HOST'),
          api_key: ENV.fetch('TENANCY_API_KEY')
        )
      end

      def sql_tenancies_matching_criteria_gateway
        Hackney::Income::SqlTenanciesMatchingCriteriaGateway.new
      end

      def background_job_gateway
        Hackney::Income::BackgroundJobGateway.new
      end
    end
  end
end
