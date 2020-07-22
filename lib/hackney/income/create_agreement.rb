module Hackney
  module Income
    class CreateAgreement
      def initialize(add_action_diary:, cancel_agreement:)
        @add_action_diary = add_action_diary
        @cancel_agreement = cancel_agreement
      end

      def find_case_details(tenancy_ref)
        Hackney::Income::Models::CasePriority.where(tenancy_ref: tenancy_ref).first
      end

      def create_agreement(agreement_params)
        new_agreement = Hackney::Income::Models::Agreement.create!(agreement_params)
        Hackney::Income::Models::AgreementState.create!(agreement_id: new_agreement.id, agreement_state: :live)

        new_agreement
      end

      def add_action_diary_entry(tenancy_ref:, comment:, created_by:)
        @add_action_diary.execute(
          tenancy_ref: tenancy_ref,
          action_code: 'AGR',
          comment: comment,
          username: created_by
        )
      end

      def cancel_active_agreements(active_agreements)
        active_agreements.each do |agreement|
          @cancel_agreement.execute(agreement_id: agreement.id)
        end
      end
    end
  end
end
