module Hackney
  module IncomeCollection
    class Letter
      class InformalAgreement < Hackney::IncomeCollection::Letter
        TEMPLATE_PATHS = [
          'lib/hackney/pdf/templates/income/informal_agreement_confirmation_letter.erb'
        ].freeze
        MANDATORY_FIELDS = %i[rent_charge instalment_amount total_amount_payable date_of_first_payment]

        def initialize(params)
          super(params)

          validated_params = validate_mandatory_fields(MANDATORY_FIELDS, params)
          @agreement = find_agreement(validated_params[:tenancy_ref])
          @rent = find_rent(validated_params[:tenancy_ref])
          @rent_charge = format('%.2f', calculate_rent(@rent, @agreement.frequency))
          @instalment_amount = @agreement.amount
          @date_of_first_payment = format_date(@agreement.start_date)
          @total_amount_payable = format('%.2f', calculate_total_amount_payable(@rent_charge, @instalment_amount))
        end

        private

        def format_date(date)
          date.strftime('%d %B %Y')
        end

        def find_rent(tenancy_ref)
          cases = Hackney::Income::Models::CasePriority.where(tenancy_ref: tenancy_ref).first

          cases.weekly_rent
        end

        def find_agreement(tenancy_ref)
          Hackney::Income::Models::Agreement.where(tenancy_ref: tenancy_ref).first
        end

        def calculate_rent(rent, frequency)
          case frequency
          when 'monthly'
            rent = (rent * 52) / 12
          when 'fortnightly'
            rent = rent * 2
          when '4 weekly'
            rent = rent * 4
          else
            rent
          end
          BigDecimal(rent.to_s)
        end

        def calculate_total_amount_payable(rent, instalment_amount)
          BigDecimal(rent.to_s) + BigDecimal(instalment_amount.to_s)
        end
      end
    end
  end
end
