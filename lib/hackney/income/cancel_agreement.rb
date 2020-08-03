module Hackney
  module Income
    class CancelAgreement
      def execute(agreement_id:)
        agreement = Hackney::Income::Models::Agreement.find_by_id(agreement_id)

        return if agreement.nil?
        return agreement unless agreement.active?

        Hackney::Income::Models::AgreementState.create!(
          agreement: agreement,
          agreement_state: :cancelled,
          description: Date.today.strftime('Cancelled on %m/%d/%Y')
        )

        agreement
      end
    end
  end
end
