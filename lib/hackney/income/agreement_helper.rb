module Hackney
  module Income
    module AgreementHelper
      def create_agreement_response(agreement:)
        {
          id: agreement.id,
          tenancyRef: agreement.tenancy_ref,
          agreementType: agreement.agreement_type,
          startingBalance: agreement.starting_balance,
          amount: agreement.amount,
          startDate: agreement.start_date,
          frequency: agreement.frequency,
          currentState: agreement.current_state,
          history: agreement_state_history(agreement.agreement_states)
        }
      end

      def agreement_state_history(agreement_states)
        agreement_states.map do |state|
          {
            state: state.agreement_state,
            date: state.created_at
          }
        end
      end
    end
  end
end
