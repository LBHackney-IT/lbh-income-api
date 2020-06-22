module Hackney
  module Income
    class ViewAgreements
      include AgreementResponseHelper

      def execute(tenancy_ref:)
        requested_agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).includes(:agreement_states)

        return [] unless requested_agreements.any?

        requested_agreements
      end
    end
  end
end
