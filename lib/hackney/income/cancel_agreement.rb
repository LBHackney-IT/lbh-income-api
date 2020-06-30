module Hackney
  module Income
    class CancelAgreement
      def execute(agreement_id:)
        agreement = Hackney::Income::Models::Agreement.find(agreement_id)

        return agreement if agreement.current_state == 'cancelled'

        Hackney::Income::Models::AgreementState.create!(agreement_id: agreement_id, agreement_state: 'cancelled')

        agreement
      end
    end
  end
end
