module Hackney
  module Leasehold
    class StoredTenanciesGateway
      GatewayModel = Hackney::Leasehold::CaseAttributes

      def store_tenancy(tenancy_ref:, criteria:)
        gateway_model_instance = GatewayModel.find_or_initialize_by(tenancy_ref: tenancy_ref)

        begin
          gateway_model_instance.tap do |tenancy|
            tenancy.assign_attributes(
              balance: criteria.balance,
              payment_ref: criteria.payment_ref,
              patch: criteria.patch_code,
              property_address: criteria.property_address,
              lessee: criteria.lessee,
              tenure_type: criteria.tenure_type,
              direct_debit_status: criteria.direct_debit_status,
              latest_letter: criteria.latest_letter,
              latest_letter_date: criteria.latest_letter_date
            )

            tenancy.save! if tenancy.changed?
          end
        rescue ActiveRecord::RecordNotUnique
          Rails.logger.error("A Tenancy with tenancy_ref: '#{tenancy_ref}' was inserted during find_or_create_by create operation, retrying...")
          retry
        end
      end
    end
  end
end
