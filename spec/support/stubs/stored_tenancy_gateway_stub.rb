module Hackney
  module Income
    class StoredTenancyGatewayStub
      def initialize(stored_tenancies_attributes)
        @stored_tenancies_attributes = stored_tenancies_attributes
      end

      def get_tenancies(page_number:, number_per_page:, filters: {})
        @stored_tenancies_attributes.values
      end

      def number_of_pages(number_per_page:, is_paused: nil, filters: {})
        @stored_tenancies_attributes.keys.count
      end
    end
  end
end
