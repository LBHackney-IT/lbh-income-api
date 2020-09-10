module Hackney
  module IncomeCollection
    class Letter
      class CourtOutcome < Hackney::IncomeCollection::Letter
        include LetterDateHelper

        TEMPLATE_PATHS = [
          'lib/hackney/pdf/templates/income/court_outcome_letter.erb'
        ].freeze
        MANDATORY_FIELDS = %i[court_outcome].freeze

        attr_reader :court_outcome, :court_hearing_arrears, :instalment_amount, :frequency, :rent, :weekly_payment, :date_of_first_payment

        def initialize(params)
          super(params)

          validated_params = validate_mandatory_fields(MANDATORY_FIELDS, params)
          @court_outcome = validated_params[:court_outcome]


          @court_hearing_arrears = validated_params[:court_hearing_arrears]
          @instalment_amount = format('%.2f', validated_params[:amount]) unless validated_params[:amount].nil?
          @frequency = validated_params[:frequency]
          @rent = validated_params[:rent]
          @weekly_payment = validated_params[:weekly_payment]
          @date_of_first_payment = format_date(validated_params[:date_of_first_payment])
          validate_informal_agreement_fields_exist
        end

        private

        def formal_agreement?
          @court_hearing_arrears.present?
        end

        def outright_order?
        @court_outcome == Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH || Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
        end

        def validate_informal_agreement_fields_exist
          if formal_agreement?
          @errors.concat(name: @court_hearing_arrears.to_s, message: 'missing mandatory field') if @court_hearing_arrears.nil?
          @errors.concat(name: @instalment_amount.to_s, message: 'missing mandatory field') if @instalment_amount.nil?
          @errors.concat(name: @frequency.to_s, message: 'missing mandatory field') if @frequency.nil?
          @errors.concat(name: @rent.to_s, message: 'missing mandatory field') if @rent.nil?
          @errors.concat(name: @weekly_payment.to_s, message: 'missing mandatory field') if @weekly_payment.nil?
          @errors.concat(name: @date_of_first_payment.to_s, message: 'missing mandatory field') if @date_of_first_payment.nil?
          end
        end
      end
    end
  end
end
