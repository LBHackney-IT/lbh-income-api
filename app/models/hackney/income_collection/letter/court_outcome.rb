module Hackney
  module IncomeCollection
    class Letter
      class CourtOutcome < Hackney::IncomeCollection::Letter
        include LetterDateHelper

        TEMPLATE_PATHS = [
          'lib/hackney/pdf/templates/income/court_outcome_letter.erb'
        ].freeze
        MANDATORY_FIELDS = %i[court_outcome, court_date].freeze

        attr_reader :court_outcome, :court_date, :balance_on_court_outcome_date, :instalment_amount, :frequency, :rent, :date_of_first_payment, :eviction_date, :rent_charge, :total_amount_payable, :formal_agreement

        def initialize(params)
          super(params)
          p ' --------------------'
          pp params
          p ' --------------------'
          pp "if formal_agreement? #{formal_agreement?}"
          pp "if outright_order?? #{outright_order?}"
          p ' --------------------'

          mandatory_outcome_fields = MANDATORY_FIELDS

          mandatory_outcome_fields = MANDATORY_FIELDS + %i[balance_on_court_outcome_date instalment_amount frequency rent date_of_first_payment rent_charge total_amount_payable] if formal_agreement?

          mandatory_outcome_fields = MANDATORY_FIELDS + %i[eviction_date] if outright_order?

          validated_params = validate_mandatory_fields(mandatory_outcome_fields, params)

          @court_outcome = validated_params[:court_outcome]
          @court_date = format_date(court_date)


          if formal_agreement?
            @balance_on_court_outcome_date = validated_params[:balance_on_court_outcome_date]
            @instalment_amount = format('%.2f', validated_params[:amount]) unless validated_params[:amount].nil?
            @agreement_frequency = validated_params[:frequency]
            @rent = validated_params[:rent]
            @date_of_first_payment = format_date(validated_params[:date_of_first_payment])
            @rent_charge = format('%.2f', calculate_rent(@rent, @agreement_frequency))
            @total_amount_payable = format('%.2f', calculate_total_amount_payable(@rent_charge, @instalment_amount))
          end

          if outright_order?
            @eviction_date = format_date(validated_params[:eviction_date])
          end

        end

        def formal_agreement?
          @balance_on_court_outcome_date.present?
        end

        def outright_order?
          [
              Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH,
              Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
          ].include?(@court_outcome)
        end
      end
    end
  end
end
