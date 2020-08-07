module Hackney
  module Income
    class ViewCases
      Response = Struct.new(:cases, :number_of_pages)

      def initialize(tenancy_api_gateway:, stored_worktray_item_gateway:)
        @tenancy_api_gateway = tenancy_api_gateway
        @stored_worktray_item_gateway = stored_worktray_item_gateway
      end

      def execute(page_number:, number_per_page:, filters: {})
        number_of_pages = @stored_worktray_item_gateway.number_of_pages(
          number_per_page: number_per_page,
          filters: filters
        )
        return Response.new([], 0) if number_of_pages.zero?

        tenancies = @stored_worktray_item_gateway.get_tenancies(
          page_number: page_number,
          number_per_page: number_per_page,
          filters: filters
        )

        case_priority_refs = tenancies.map { |t| t.fetch(:tenancy_ref) }
        full_tenancies = @tenancy_api_gateway.get_tenancies_by_refs(case_priority_refs)

        cases = tenancies.map do |case_priority|
          tenancy = full_tenancies.find { |t| t.fetch(:ref) == case_priority.fetch(:tenancy_ref) }
          next if tenancy.nil?

          build_tenancy_list_item(tenancy, case_priority)
        end.compact

        Response.new(cases, number_of_pages)
      end

      private

      def build_tenancy_list_item(tenancy, case_priority)
        {
          ref: tenancy.fetch(:ref),
          current_balance: tenancy.fetch(:current_balance),
          current_arrears_agreement_status: tenancy.fetch(:current_arrears_agreement_status),
          latest_action: {
            code: tenancy.dig(:latest_action, :code),
            date: tenancy.dig(:latest_action, :date)
          },
          primary_contact: {
            name: tenancy.dig(:primary_contact, :name),
            short_address: tenancy.dig(:primary_contact, :short_address),
            postcode: tenancy.dig(:primary_contact, :postcode)
          },

          balance: case_priority.fetch(:balance),
          days_in_arrears: case_priority.fetch(:days_in_arrears),
          days_since_last_payment: case_priority.fetch(:days_since_last_payment),
          number_of_broken_agreements: case_priority.fetch(:number_of_broken_agreements),
          active_agreement: case_priority.fetch(:active_agreement),
          broken_court_order: case_priority.fetch(:broken_court_order),
          nosp_served: case_priority.fetch(:nosp_served),
          active_nosp: case_priority.fetch(:active_nosp),
          courtdate: case_priority.fetch(:courtdate),
          court_outcome: case_priority.fetch(:court_outcome),
          eviction_date: case_priority.fetch(:eviction_date),
          classification: case_priority.fetch(:classification),
          patch_code: case_priority.fetch(:patch_code),
          latest_active_agreement_date: case_priority.fetch(:latest_active_agreement_date),
          breach_agreement_date: case_priority.fetch(:latest_active_agreement_date),
          expected_balance: case_priority.fetch(:expected_balance),
          pause: {
            reason: case_priority.fetch(:pause_reason),
            comment: case_priority.fetch(:pause_comment),
            until: case_priority.fetch(:is_paused_until)
          }
        }
      end
    end
  end
end
