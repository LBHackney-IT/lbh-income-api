module Hackney
  module Income
    class ViewMyCases
      Response = Struct.new(:cases, :number_of_pages)

      def initialize(tenancy_api_gateway:, stored_tenancies_gateway:)
        @tenancy_api_gateway = tenancy_api_gateway
        @stored_tenancies_gateway = stored_tenancies_gateway
      end

      def execute(page_number:, number_per_page:, filters: {})
        number_of_pages = @stored_tenancies_gateway.number_of_pages(
          number_per_page: number_per_page,
          filters: filters
        )
        return Response.new([], 0) if number_of_pages.zero?

        tenancies = @stored_tenancies_gateway.get_tenancies(
          page_number: page_number,
          number_per_page: number_per_page,
          filters: filters
        )

        assigned_tenancy_refs = tenancies.map { |t| t.fetch(:tenancy_ref) }
        full_tenancies = @tenancy_api_gateway.get_tenancies_by_refs(assigned_tenancy_refs)

        cases = tenancies.map do |assigned_tenancy|
          tenancy = full_tenancies.find { |t| t.fetch(:ref) == assigned_tenancy.fetch(:tenancy_ref) }
          next if tenancy.nil?

          build_tenancy_list_item(tenancy, assigned_tenancy)
        end.compact

        Response.new(cases, number_of_pages)
      end

      private

      def build_tenancy_list_item(tenancy, assigned_tenancy)
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
          priority_band: assigned_tenancy.fetch(:priority_band),
          priority_score: assigned_tenancy.fetch(:priority_score),

          balance_contribution: assigned_tenancy.fetch(:balance_contribution),
          days_in_arrears_contribution: assigned_tenancy.fetch(:days_in_arrears_contribution),
          days_since_last_payment_contribution: assigned_tenancy.fetch(:days_since_last_payment_contribution),
          payment_amount_delta_contribution: assigned_tenancy.fetch(:payment_amount_delta_contribution),
          payment_date_delta_contribution: assigned_tenancy.fetch(:payment_date_delta_contribution),
          number_of_broken_agreements_contribution: assigned_tenancy.fetch(:number_of_broken_agreements_contribution),
          active_agreement_contribution: assigned_tenancy.fetch(:active_agreement_contribution),
          broken_court_order_contribution: assigned_tenancy.fetch(:broken_court_order_contribution),
          nosp_served_contribution: assigned_tenancy.fetch(:nosp_served_contribution),
          active_nosp_contribution: assigned_tenancy.fetch(:active_nosp_contribution),

          balance: assigned_tenancy.fetch(:balance),
          days_in_arrears: assigned_tenancy.fetch(:days_in_arrears),
          days_since_last_payment: assigned_tenancy.fetch(:days_since_last_payment),
          payment_amount_delta: assigned_tenancy.fetch(:payment_amount_delta),
          payment_date_delta: assigned_tenancy.fetch(:payment_date_delta),
          number_of_broken_agreements: assigned_tenancy.fetch(:number_of_broken_agreements),
          active_agreement: assigned_tenancy.fetch(:active_agreement),
          broken_court_order: assigned_tenancy.fetch(:broken_court_order),
          nosp_served: assigned_tenancy.fetch(:nosp_served),
          active_nosp: assigned_tenancy.fetch(:active_nosp),

          courtdate: assigned_tenancy.fetch(:courtdate),
          court_outcome: assigned_tenancy.fetch(:court_outcome),

          classification: assigned_tenancy.fetch(:classification)
        }
      end
    end
  end
end
