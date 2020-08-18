module Hackney
  module IncomeCollection
    class Letter
      class InformalAgreement < Hackney::IncomeCollection::Letter
        TEMPLATE_PATHS = [
          'lib/hackney/pdf/templates/income/informal_agreement_confirmation_letter.erb'
        ].freeze
        MANDATORY_FIELDS = %i[rent agreement_frequency amount rent_charge instalment_amount total_amount_payable date_of_first_payment]

        attr_reader :rent, :agreement_frequency, :amount, :rent_charge, :total_amount_payable, :date_of_first_payment

        def initialize(params)
          super(params)

          validated_params = validate_mandatory_fields(MANDATORY_FIELDS, params)
          @agreement_frequency = validated_params[:agreement_frequency]
          @rent = validated_params[:rent]
          @rent_charge = format('%.2f', calculate_rent(@rent, @agreement_frequency))
          @instalment_amount = validated_params[:amount]
          @date_of_first_payment = validated_params[:date_of_first_payment]
          @total_amount_payable = format('%.2f', calculate_total_amount_payable(@rent_charge, @instalment_amount))
        end

        private

        def format_date(date)
          date.strftime('%d %B %Y')
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
