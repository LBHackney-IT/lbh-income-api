module Hackney
  module Income
    class FetchActions
      Response = Struct.new(:actions, :number_of_pages)

      def initialize(tenancy_api_gateway:, stored_actions_gateway:)
        @tenancy_api_gateway = tenancy_api_gateway
        @stored_actions_gateway = stored_actions_gateway
      end

      def execute(page_number:, number_per_page:, filters: {}, service_area:)
        number_of_pages = @stored_actions_gateway.number_of_pages(
          number_per_page: number_per_page,
          filters: filters
        )
        return Response.new([], 0) if number_of_pages.zero?

        tenancies = @stored_actions_gateway.get_actions(
          page_number: page_number,
          number_per_page: number_per_page,
          filters: filters
        )
        byebug
        Response.new(tenancies, number_of_pages)
      end
    end
  end
end
