module Hackney
  module Income
    class SyncCasePriority
      WorktrayItemModel = Hackney::Income::Models::CasePriority
      DocumentModel = Hackney::Cloud::Document
      AgreementModel = Hackney::Income::Models::Agreement

      def initialize(prioritisation_gateway:, stored_worktray_item_gateway:, automate_sending_letters:, update_agreement_state:)
        @automate_sending_letters = automate_sending_letters
        @prioritisation_gateway = prioritisation_gateway
        @stored_worktray_item_gateway = stored_worktray_item_gateway
        @update_agreement_state = update_agreement_state
      end

      def execute(tenancy_ref:)
        criteria = @prioritisation_gateway.priorities_for_tenancy(tenancy_ref).fetch(:criteria)
        documents = DocumentModel.exclude_uploaded.by_payment_ref(criteria.payment_ref)
        agreement = AgreementModel.where(tenancy_ref: tenancy_ref).select(&:active?).last

        @update_agreement_state.execute(agreement: agreement, current_balance: criteria.balance) unless agreement.nil?

        classification = Hackney::Income::TenancyClassification::Classifier.new(
          WorktrayItemModel.find_or_initialize_by(tenancy_ref: tenancy_ref),
          criteria,
          documents
        ).execute

        case_priority = @stored_worktray_item_gateway.store_worktray_item(
          tenancy_ref: tenancy_ref,
          criteria: criteria,
          classification: classification
        )

        @automate_sending_letters.execute(case_priority: case_priority) unless case_priority.paused?

        nil
      end
    end
  end
end
