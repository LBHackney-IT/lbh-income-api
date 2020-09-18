module Hackney
  module IncomeCollection
    class Letter
      class CourtOutcome
        class WithTerms < Hackney::IncomeCollection::Letter::CourtOutcome
          include LetterDateHelper

          MANDATORY_FIELDS = %i[balance_on_court_outcome_date amount agreement_frequency rent date_of_first_payment].freeze

          attr_reader :balance_on_court_outcome_date, :instalment_amount, :agreement_frequency, :rent, :date_of_first_payment,
                      :rent_charge, :total_amount_payable, :initial_payment_amount, :initial_payment_date

          def initialize(params)
            super(params)

            validated_params = validate_mandatory_fields(MANDATORY_FIELDS, params)

            @balance_on_court_outcome_date = validated_params[:balance_on_court_outcome_date]
            @instalment_amount = format('%.2f', validated_params[:amount]) unless validated_params[:amount].nil?
            @agreement_frequency = validated_params[:agreement_frequency]
            @rent = validated_params[:rent]
            @date_of_first_payment = format_date(validated_params[:date_of_first_payment])
            @rent_charge = format('%.2f', calculate_rent(@rent, @agreement_frequency))
            @total_amount_payable = format('%.2f', calculate_total_amount_payable(@rent_charge, @instalment_amount))
            @initial_payment_amount = format('%.2f', params[:initial_payment_amount]) unless params[:initial_payment_amount].nil?
            @initial_payment_date = format_date(params[:initial_payment_date]) unless params[:initial_payment_date].nil?
          end
        end
      end
    end
  end
end
