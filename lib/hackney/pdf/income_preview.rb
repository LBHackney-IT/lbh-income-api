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

        if court_case
          court_case_data = get_court_info(court_case, agreement)

          letter_params = income_info.merge(court_case_data)

          letter_params = income_info
        end

        if agreement

          if agreement.breached?
            agreement_data = agreement.formal? ? get_breached_formal_agreement_info(agreement) : get_breached_agreement_info(agreement)
          else
            agreement_data = get_agreement_info(agreement)
          end

          letter_params = income_info.merge(agreement_data)

        else
          letter_params = income_info
        end

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
          date_of_first_payment: agreement.start_date
        }
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

      def get_court_info(court_case, agreement=nil)
        court_details = { court_outcome: court_case.court_outcome }
        court_details[:court_hearing_arrears] = court_case.balance_on_court_outcome_date if agreement

        court_details
      end
    end
  end
end
