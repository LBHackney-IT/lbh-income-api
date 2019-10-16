module Hackney
  module Income
    class StoredTenancyGatewayStub
      def initialize(stored_tenancies_attributes)
        @stored_tenancies_attributes = stored_tenancies_attributes
      end

      def get_tenancies_for_user(user_id:, page_number:, number_per_page:, is_paused: nil, classification: nil)
        @stored_tenancies_attributes.values
      end

      def number_of_pages_for_user(user_id:, number_per_page:, is_paused: nil, classification: nil)
        @stored_tenancies_attributes.keys.count
      end
    end
  end
end
