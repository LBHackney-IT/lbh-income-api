module Hackney
  module Income
    class SyncCasePriority
      def initialize(prioritisation_gateway:, stored_worktray_item_gateway:, automate_sending_letters:)
        @automate_sending_letters = automate_sending_letters
        @prioritisation_gateway = prioritisation_gateway
        @stored_worktray_item_gateway = stored_worktray_item_gateway
      end

      def execute(tenancy_ref:)
        criteria = @prioritisation_gateway.priorities_for_tenancy(tenancy_ref).fetch(:criteria)
        documents = Hackney::Cloud::Document.exclude_uploaded.by_payment_ref(criteria.payment_ref)
        classification = Hackney::Income::TenancyClassification::Classifier.new(
          Hackney::Income::Models::CasePriority.find_or_initialize_by(tenancy_ref: tenancy_ref),
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
