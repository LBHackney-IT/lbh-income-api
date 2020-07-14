module Hackney
  module Leasehold
    class StoredActionGateway
      GatewayModel = Hackney::IncomeCollection::Action
      SERVICE_AREA = 'leasehold'.freeze

      def store_action(tenancy_ref:, criteria:)
        gateway_model_instance = GatewayModel.find_or_initialize_by(tenancy_ref: tenancy_ref)

        begin
          gateway_model_instance.tap do |action|
            action.assign_attributes(
              balance: criteria.balance,
              payment_ref: criteria.payment_ref,
              patch_code: criteria.patch_code,
              action_type: criteria.tenure_type,
              service_area_type: SERVICE_AREA,
              metadata: {
                property_address: criteria.property_address,
                lessee: criteria.lessee,
                tenure_type: criteria.tenure_type,
                direct_debit_status: criteria.direct_debit_status,
                latest_letter: criteria.latest_letter,
                latest_letter_date: criteria.latest_letter_date
              }
            )

            action.save! if action.changed?
          end
          
        rescue ActiveRecord::RecordNotUnique
          Rails.logger.error("An action with tenancy_ref: '#{tenancy_ref}' was inserted during find_or_create_by create operation, retrying...")
          retry
        end
      end
    end
  end
end
