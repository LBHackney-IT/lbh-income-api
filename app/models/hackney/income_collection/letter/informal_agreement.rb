module Hackney
  module IncomeCollection
    class Letter
      class InformalAgreement < Hackney::IncomeCollection::Letter
        include LetterDateHelper

        TEMPLATE_PATHS = [
          'lib/hackney/pdf/templates/income/informal_agreement_confirmation_letter.erb'
        ].freeze
        MANDATORY_FIELDS = %i[rent agreement_frequency amount date_of_first_payment].freeze

        attr_reader :rent, :agreement_frequency, :amount, :rent_charge, :total_amount_payable, :date_of_first_payment, :instalment_amount

        def initialize(params)
          super(params)

          validated_params = validate_mandatory_fields(MANDATORY_FIELDS, params)
          @agreement_frequency = validated_params[:agreement_frequency]
          @rent = validated_params[:rent]
          @instalment_amount = format('%.2f', validated_params[:amount]) unless validated_params[:amount].nil?
          @date_of_first_payment = format_date(validated_params[:date_of_first_payment])

          return unless @rent
          @rent_charge = format('%.2f', calculate_rent(@rent, @agreement_frequency))
          @total_amount_payable = format('%.2f', calculate_total_amount_payable(@rent_charge, @instalment_amount))
        end
      end
    end
  end
end
