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

      def create_agreement(agreement_params, state_params = {})
        new_agreement = Hackney::Income::Models::Agreement.create!(agreement_params)
        Hackney::Income::Models::AgreementState.create!(
          agreement: new_agreement,
          agreement_state: state_params[:agreement_state] || :live,
          expected_balance: state_params[:expected_balance] || new_agreement[:starting_balance],
          checked_balance: state_params[:checked_balance] || new_agreement[:starting_balance],
          description: state_params[:description] || 'Agreement created'
        )

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

      def assign_agreement_params(params)
        {
          tenancy_ref: params[:tenancy_ref],
          amount: params[:amount],
          start_date: params[:start_date],
          frequency: params[:frequency],
          created_by: params[:created_by],
          notes: params[:notes],
          initial_payment_amount: params[:initial_payment_amount],
          initial_payment_date: params[:initial_payment_date]
        }
      end
    end
  end
end
