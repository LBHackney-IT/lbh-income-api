module Hackney
  module PDF
    class IncomePreview
      def initialize(get_templates_gateway:, income_information_gateway:, tenancy_case_gateway:)
        @get_templates_gateway = get_templates_gateway
        @income_information_gateway = income_information_gateway
        @tenancy_case_gateway = tenancy_case_gateway
      end

      def execute(tenancy_ref:, template_id:, user:)
        template = get_template_by_id(template_id, user)
        income_info = get_income_info(tenancy_ref)
        agreement_info = get_agreement_info(tenancy_ref)
        letter_params = income_info.merge(agreement_info)

        preview_with_errors = Hackney::PDF::IncomePreviewGenerator.new(
          template_path: template[:path]
        ).execute(letter_params: letter_params, username: user.name)

        uuid = SecureRandom.uuid

        {
          case: income_info,
          template: template,
          uuid: uuid,
          username: user.name,
          preview: preview_with_errors[:html],
          errors: preview_with_errors[:errors]
        }
      end

      private

      def get_income_info(tenancy_ref)
        info_from_uh = @income_information_gateway.get_income_info(tenancy_ref: tenancy_ref)
        stored_info = @tenancy_case_gateway.find(tenancy_ref: tenancy_ref)
        info_from_uh[:total_collectable_arrears_balance] = stored_info.collectable_arrears
        info_from_uh
      end

      def get_template_by_id(template_id, user)
        templates = @get_templates_gateway.execute(user: user)
        templates[templates.index { |temp| temp[:id] == template_id }]
      end

      def get_agreement_info(tenancy_ref)
        case_priority = Hackney::Income::Models::CasePriority.where(tenancy_ref: tenancy_ref).first
        agreement = Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).first

        {
          rent: case_priority.weekly_rent
          agreement_frequency: agreement.frequency,
          amount: agreement.amount,
          date_of_first_payment: agreement.start_date
        }
      end
    end
  end
end
