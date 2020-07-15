module Hackney
  module PDF
    class UseCaseFactory
      def get_templates
        Hackney::PDF::GetTemplatesForUser.new
      end

      def get_preview
        Hackney::PDF::Preview.new(
          get_templates_gateway: get_templates,
          leasehold_information_gateway: Hackney::Income::UniversalHousingLeaseholdGateway.new
        )
      end

      def get_income_preview
        Hackney::PDF::IncomePreview.new(
          get_templates_gateway: get_templates,
          income_information_gateway: Hackney::Income::UniversalHousingIncomeGateway.new,
          tenancy_case_gateway: Hackney::Income::SqlTenancyCaseGateway.new
        )
      end
    end
  end
end
