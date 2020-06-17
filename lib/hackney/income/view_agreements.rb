module Hackney
  module Income
    class ViewAgreements
      include AgreementHelper

      def execute(tenancy_ref:)
        requested_agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).includes(:agreement_states)

        agreements = requested_agreements.map do |agreement|
          create_agreement_response(agreement: agreement)
        end

        { agreements: agreements }
      end
    end
  end
end
