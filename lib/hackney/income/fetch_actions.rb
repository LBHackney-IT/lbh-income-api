module Hackney
  module Income
    class FetchActions
      Response = Struct.new(:actions, :number_of_pages)

      def initialize(fetch_actions_gateway:)
        @fetch_actions_gateway = fetch_actions_gateway
      end

      def execute(page_number:, number_per_page:, filters: {}, service_area_type:)
        number_of_pages = @fetch_actions_gateway.number_of_pages(
          service_area_type: service_area_type,
          number_per_page: number_per_page,
          filters: filters
        )
        return Response.new([], 0) if number_of_pages.zero?

        tenancies = @fetch_actions_gateway.get_actions(
          service_area_type: service_area_type,
          page_number: page_number,
          number_per_page: number_per_page,
          filters: filters
        )

        Response.new(tenancies, number_of_pages)
      end
    end
  end
end
