module Hackney
  module IncomeCollection
    class Letter
      class CourtOutcome < Hackney::IncomeCollection::Letter
        include LetterDateHelper

        TEMPLATE_PATHS = [
          'lib/hackney/pdf/templates/income/court_outcome_letter.erb'
        ].freeze
        MANDATORY_FIELDS = %i[court_outcome].freeze

        attr_reader :court_outcome, :court_hearing_arrears, :instalment_amount, :frequency, :rent, :date_of_first_payment, :eviction_date, :rent_charge, :total_amount_payable

        def initialize(params)
          super(params)
          if formal_agreement?
            mandatory_outcome_fields = MANDATORY_FIELDS + %i[court_hearing_arrears instalment_amount frequency rent date_of_first_payment rent_charge total_amount_payable]
          elsif outright_order?
            mandatory_outcome_fields = MANDATORY_FIELDS + %i[eviction_date]
          elsif formal_agreement? && outright_order?
            mandatory_outcome_fields = MANDATORY_FIELDS + %i[court_hearing_arrears instalment_amount frequency rent date_of_first_payment eviction_date rent_charge total_amount_payable]
          else
            mandatory_outcome_fields = MANDATORY_FIELDS
          end

          validated_params = validate_mandatory_fields(mandatory_outcome_fields, params)
          @court_outcome = validated_params[:court_outcome]

          @court_hearing_arrears = validated_params[:court_hearing_arrears]
          @instalment_amount = format('%.2f', validated_params[:amount]) unless validated_params[:amount].nil?
          @agreement_frequency = validated_params[:frequency]
          @rent = validated_params[:rent]
          @date_of_first_payment = format_date(validated_params[:date_of_first_payment])
          @eviction_date = format_date(validated_params[:eviction_date])
          @rent_charge = format('%.2f', calculate_rent(@rent, @agreement_frequency))
          @total_amount_payable = format('%.2f', calculate_total_amount_payable(@rent_charge, @instalment_amount))
        end

        private

        def formal_agreement?
          @court_hearing_arrears.present?
        end

        def outright_order?
        @court_outcome == Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH || Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
        end
      end
    end
  end
end
