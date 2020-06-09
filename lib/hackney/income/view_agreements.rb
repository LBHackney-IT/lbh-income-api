module Hackney
  module Income
    class ViewAgreements
      def self.execute(tenancy_ref:)
        requested_agreements = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref)

        agreements = requested_agreements.map do |agreement|
          {
            tenancyRef: agreement.tenancy_ref,
          }
        end

        { agreements: agreements}
      end
    end
  end
end
