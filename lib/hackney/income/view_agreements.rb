module Hackney
  module Income
    class ViewAgreements
      def self.execute(tenancy_ref:)
        requested_agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref)

        agreements = requested_agreements.map do |agreement|
          {
            tenancyRef: agreement.tenancy_ref,
            agreementType: agreement.agreement_type,
            startingBalance: agreement.starting_balance,
            amount: agreement.amount,
            startDate: agreement.start_date,
            frequency: agreement.frequency,
            history: []
          }
        end

        { agreements: agreements }
      end
    end
  end
end
