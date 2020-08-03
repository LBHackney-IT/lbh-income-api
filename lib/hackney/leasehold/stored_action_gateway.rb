module Hackney
  module Leasehold
    class StoredActionGateway
      GatewayModel = Hackney::IncomeCollection::Action
      SERVICE_AREA = 'leasehold'.freeze

      def store_action(tenancy_ref:, attributes:)
        gateway_model_instance = GatewayModel.find_or_initialize_by(tenancy_ref: tenancy_ref)

        begin
          gateway_model_instance.tap do |action|
            action.assign_attributes(
              balance: attributes.balance,
              payment_ref: attributes.payment_ref,
              patch_code: attributes.patch_code,
              action_type: attributes.tenure_type,
              service_area_type: SERVICE_AREA,
              metadata: {
                property_address: attributes.property_address,
                lessee: attributes.lessee,
                tenure_type: attributes.tenure_type,
                direct_debit_status: attributes.direct_debit_status,
                latest_letter: attributes.latest_letter,
                latest_letter_date: attributes.latest_letter_date
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
