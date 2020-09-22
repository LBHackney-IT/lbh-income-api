module Hackney
  module Income
    class CancelAgreement
      def execute(agreement_id:, cancelled_by:, cancellation_reason:)
        agreement = Hackney::Income::Models::Agreement.find_by_id(agreement_id)

        return if agreement.nil?
        return agreement unless agreement.active?

        Hackney::Income::Models::AgreementState.create!(
          agreement: agreement,
          agreement_state: :cancelled,
          description: "Cancelled by #{cancelled_by}, reason: #{cancellation_reason}"
        )

        agreement
      end
    end
  end
end
