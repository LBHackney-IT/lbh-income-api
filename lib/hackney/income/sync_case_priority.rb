module Hackney
  module Income
    class SyncCasePriority
      WorktrayItemModel = Hackney::Income::Models::CasePriority
      DocumentModel = Hackney::Cloud::Document
      AgreementModel = Hackney::Income::Models::Agreement

      def initialize(
        prioritisation_gateway:,
        stored_worktray_item_gateway:,
        automate_sending_letters:,
        update_agreement_state:,
        migrate_court_case_usecase:,
        migrate_uh_agreement:,
        migrate_uh_eviction:
      )
        @automate_sending_letters = automate_sending_letters
        @prioritisation_gateway = prioritisation_gateway
        @stored_worktray_item_gateway = stored_worktray_item_gateway
        @update_agreement_state = update_agreement_state
        @migrate_court_case_usecase = migrate_court_case_usecase
        @migrate_uh_agreement = migrate_uh_agreement
        @migrate_uh_eviction = migrate_uh_eviction
      end

      def execute(tenancy_ref:)
        criteria = @prioritisation_gateway.priorities_for_tenancy(tenancy_ref).fetch(:criteria)

        migrate_court_case(criteria)

        migrate_eviction(criteria)

        migrate_agreements(tenancy_ref)

        detect_agreement_breaches(tenancy_ref: tenancy_ref, current_balance: criteria.balance)

        action = determine_next_recommended_action(criteria: criteria)

        case_priority = persist_worktray_item(criteria: criteria, action: action)

        send_automated_letters(case_priority: case_priority)

        nil
      end

      private

      def detect_agreement_breaches(tenancy_ref:, current_balance:)
        agreement = AgreementModel.where(tenancy_ref: tenancy_ref).select(&:active?).last

        @update_agreement_state.execute(agreement: agreement, current_balance: current_balance) unless agreement.nil?
      end

      def determine_next_recommended_action(criteria:)
        documents = DocumentModel.exclude_uploaded.by_payment_ref(criteria.payment_ref)

        Hackney::Income::TenancyClassification::Classifier.new(
          WorktrayItemModel.find_or_initialize_by(tenancy_ref: criteria.tenancy_ref),
          criteria,
          documents
        ).execute
      end

      def persist_worktray_item(criteria:, action:)
        @stored_worktray_item_gateway.store_worktray_item(
          tenancy_ref: criteria.tenancy_ref,
          criteria: criteria,
          classification: action
        )
      end

      def send_automated_letters(case_priority:)
        @automate_sending_letters.execute(case_priority: case_priority) unless case_priority.paused?
      end

      def migrate_court_case(criteria)
        @migrate_court_case_usecase.migrate(criteria)
      end

      def migrate_agreements(tenancy_ref)
        @migrate_uh_agreement.migrate(tenancy_ref: tenancy_ref)
      end

      def migrate_eviction(criteria)
        @migrate_uh_eviction.migrate(criteria)
      end
    end
  end
end
