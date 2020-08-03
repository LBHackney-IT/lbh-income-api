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

      def number_of_pages(number_of_pages:, filters: {})
        byebug
        (GatewayModel.all.count.to_f / number_per_page).ceil
      end

      def get_actions(page_number: nil, number_per_page: nil, filters: {})
        query = GatewayModel

        query = query.offset((page_number - 1) * number_per_page).limit(number_per_page) if page_number.present? && number_per_page.present?

        # order_options   = 'eviction_date' if filters[:upcoming_evictions].present?
        # order_options   = 'courtdate' if filters[:upcoming_court_dates].present?
        # order_options   = 'is_paused_until' if filters[:is_paused]
        order_options ||= by_balance

        query.order(order_options)
      end
    end
  end
end
