module Hackney
  module PDF
    class IncomePreview
      def initialize(get_templates_gateway:, income_information_gateway:, tenancy_case_gateway:)
        @get_templates_gateway = get_templates_gateway
        @income_information_gateway = income_information_gateway
        @tenancy_case_gateway = tenancy_case_gateway
      end

      def execute(tenancy_ref:, template_id:, user:, agreement: nil, court_case: nil)
        template = get_template_by_id(template_id, user)
        income_info = get_income_info(tenancy_ref)

        letter_params = income_info

        letter_params = letter_params.merge(court_outcome_params(agreement, court_case, income_info)) if court_case

        letter_params = letter_params.merge(agreement_params(agreement, income_info)) if agreement

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

      def court_outcome_params(agreement, court_case, income_info)
        court_case_data = get_court_info(court_case, agreement)

        income_info.merge(court_case_data)
      end

      def agreement_params(agreement, income_info)
        if agreement.breached?
          agreement_data = agreement.formal? ? get_breached_formal_agreement_info(agreement) : get_breached_agreement_info(agreement)
        else
          agreement_data = get_agreement_info(agreement)
        end

        income_info.merge(agreement_data)
      end

      def get_income_info(tenancy_ref)
        info_from_uh = @income_information_gateway.get_income_info(tenancy_ref: tenancy_ref)
        stored_info = @tenancy_case_gateway.find(tenancy_ref: tenancy_ref)
        info_from_uh[:total_collectable_arrears_balance] = stored_info.collectable_arrears
        info_from_uh[:rent] = stored_info.weekly_rent
        info_from_uh[:eviction_date] = stored_info.eviction_date
        info_from_uh
      end

      def get_template_by_id(template_id, user)
        templates = @get_templates_gateway.execute(user: user)
        templates[templates.index { |temp| temp[:id] == template_id }]
      end

      def get_agreement_info(agreement)
        {
          agreement_frequency: agreement.frequency,
          amount: agreement.amount,
          date_of_first_payment: agreement.start_date,
          initial_payment_amount: agreement.initial_payment_amount,
          initial_payment_date: agreement.initial_payment_date
        }.compact
      end

      def get_breached_agreement_info(agreement)
        state = agreement.agreement_states.last
        {
          created_date: agreement.created_at,
          expected_balance: state.expected_balance,
          checked_balance: state.checked_balance
        }
      end

      def get_breached_formal_agreement_info(agreement)
        state = agreement.agreement_states.last

        {
          court_date: agreement.court_case.court_date,
          date_of_breach: state.created_at,
          expected_balance: state.expected_balance,
          checked_balance: state.checked_balance
        }
      end

      def get_court_info(court_case, agreement = nil)
        court_details = { court_outcome: court_case.court_outcome, court_date: court_case.court_date }
        court_details[:balance_on_court_outcome_date] = court_case.balance_on_court_outcome_date if agreement

        court_details
      end
    end
  end
end
