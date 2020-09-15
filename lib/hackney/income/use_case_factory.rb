module Hackney
  module Income
    class UseCaseFactory
      def view_cases
        Hackney::Income::ViewCases.new(
          tenancy_api_gateway: tenancy_api_gateway,
          stored_worktray_item_gateway: stored_worktray_item_gateway
        )
      end

      def fetch_actions
        Hackney::Income::FetchActions.new(
          fetch_actions_gateway: fetch_actions_gateway
        )
      end

      def fetch_actions_gateway
        Hackney::Income::FetchActionsGateway.new
      end

      def schedule_sync_cases
        Hackney::Income::ScheduleSyncCases.new(
          uh_tenancies_gateway: uh_tenancies_gateway,
          background_job_gateway: background_job_gateway
        )
      end

      def schedule_send_sms
        Hackney::Income::ScheduleSendSMS.new(
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
          add_action_diary_and_pause_case_usecase: add_action_diary_and_pause_case
        )
      end

      def send_manual_email
        Hackney::Notification::SendManualEmail.new(
          notification_gateway: notifications_gateway,
          add_action_diary_and_pause_case_usecase: add_action_diary_and_pause_case
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
          add_action_diary_and_pause_case_usecase: add_action_diary_and_pause_case,
          leasehold_gateway: Hackney::Income::UniversalHousingLeaseholdGateway.new
        )
      end

      def send_precompiled_letter_to_gov_notify
        Hackney::Notification::SendPrecompiledLetter.new(
          notification_gateway: notifications_gateway
        )
      end

      def request_precompiled_letter_state
        case_priority_store = Hackney::Income::Models
        Hackney::Notification::RequestPrecompiledLetterState.new(
          notification_gateway: notifications_gateway,
          add_action_diary_and_pause_case_usecase: add_action_diary_and_pause_case,
          case_priority_store: case_priority_store,
          document_store: cloud_storage
        )
      end

      def enqueue_request_all_precompiled_letter_states
        enqueue_job = Hackney::Income::Jobs::RequestPrecompiledLetterStateJob

        Hackney::Notification::EnqueueRequestAllPrecompiledLetterStates.new(
          enqueue_job: enqueue_job,
          document_store: cloud_storage
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

      def add_action_diary_and_pause_case
        UseCases::AddActionDiaryAndPauseCase.new(
          sql_pause_tenancy_gateway: sql_pause_tenancy_gateway,
          add_action_diary: add_action_diary,
          get_tenancy: get_tenancy
        )
      end

      def automate_sending_letters
        UseCases::AutomateSendingLetters.new(
          case_ready_for_automation: case_ready_for_letter_automation,
          case_classification_to_letter_type_map: case_classification_to_letter_type_map,
          generate_and_store_letter: generate_and_store_letter,
          send_letter_to_gov_notify: send_letter_to_gov_notify,
          set_tenancy_paused_status: set_tenancy_paused_status
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

      def case_ready_for_letter_automation
        UseCases::CaseReadyForLetterAutomation.new
      end

      def case_ready_for_sms_automation
        UseCases::CaseReadyForSmsAutomation.new
      end

      def sync_case_priority
        ActiveSupport::Deprecation.warn(
          "SyncCasePriorityJob is deprecated - use external scheduler via 'rake income:sync:enqueue'"
        )
        Hackney::Income::SyncCasePriority.new(
          automate_sending_letters: automate_sending_letters,
          prioritisation_gateway: prioritisation_gateway,
          stored_worktray_item_gateway: stored_worktray_item_gateway,
          update_agreement_state: update_agreement_state,
          migrate_court_case_usecase: migrate_court_case_usecase,
          migrate_uh_agreement: migrate_uh_agreement
        )
      end

      def migrate_uh_agreement
        Hackney::Income::MigrateUhAgreement.new(
          view_agreements: view_agreements,
          view_court_cases: view_court_cases,
          create_agreement: create_agreement,
          create_agreement_migration: create_agreement_migration
        )
      end

      def create_agreement
        Hackney::Income::CreateAgreement.new(
          add_action_diary: add_action_diary,
          cancel_agreement: cancel_agreement
        )
      end

      def create_agreement_migration
        Hackney::Income::CreateAgreementMigration.new
      end

      def migrate_court_case_usecase
        Hackney::Income::MigrateUhCourtCase.new(
          create_court_case: create_court_case,
          view_court_cases: view_court_cases,
          update_court_case: update_court_case
        )
      end

      def update_agreement_state
        Hackney::Income::UpdateAgreementState.new(
          tolerance_days: ENV['AGREEMENT_BREACH_TOLERANCE_DAYS']&.to_i || 5
        )
      end

      def update_all_agreement_states
        Hackney::Income::UpdateAllAgreementState.new(
          update_agreement_state: update_agreement_state
        )
      end

      # intended to only be used for rake task please delete when no longer required
      def show_send_sms_tenancies
        Hackney::Income::ShowSendSMSTenancies.new(
          sql_tenancies_for_messages_gateway: sql_tenancies_matching_criteria_gateway
        )
      end

      def get_failed_sms_messages
        Hackney::Notification::GetFailedSMSMessages.new(
          notification_gateway: notifications_gateway
        )
      end

      def uh_tenancies_gateway
        Hackney::Income::UniversalHousingTenanciesGateway.new(
          restrict_patches: ENV.fetch('RESTRICT_PATCHES', false),
          patches: ENV.fetch('PERMITTED_PATCHES', '').split(',')
        )
      end

      def view_agreements
        Hackney::Income::ViewAgreements.new
      end

      def create_informal_agreement
        Hackney::Income::CreateInformalAgreement.new(
          add_action_diary: add_action_diary,
          cancel_agreement: cancel_agreement
        )
      end

      def create_formal_agreement
        Hackney::Income::CreateFormalAgreement.new(
          add_action_diary: add_action_diary,
          cancel_agreement: cancel_agreement
        )
      end

      def cancel_agreement
        Hackney::Income::CancelAgreement.new
      end

      def create_court_case
        Hackney::Income::CreateCourtCase.new
      end

      def view_court_cases
        Hackney::Income::ViewCourtCases.new
      end

      def update_court_case
        Hackney::Income::UpdateCourtCase.new
      end

      def create_eviction_date
        Hackney::Income::CreateEvictionDate.new
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

      def stored_worktray_item_gateway
        Hackney::Income::WorktrayItemGateway.new
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
