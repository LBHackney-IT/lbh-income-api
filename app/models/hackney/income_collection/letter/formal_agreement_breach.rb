module Hackney
  module IncomeCollection
    class Letter
      class FormalAgreementBreach < Hackney::IncomeCollection::Letter
        include LetterDateHelper

        TEMPLATE_PATHS = [
          'lib/hackney/pdf/templates/income/formal_agreement_breach_letter.erb'
        ].freeze
        MANDATORY_FIELDS = %i[
          created_date expected_balance checked_balance shortfall_amount
          court_date date_of_breach expected_balance checked_balance
        ].freeze

        attr_reader :created_date, :expected_balance, :checked_balance, :shortfall_amount,
                    :court_date, :date_of_breach

        def initialize(params)
          super(params)

          validated_params = validate_mandatory_fields(MANDATORY_FIELDS, params)
          @created_date = format_date(validated_params[:created_date])
          @expected_balance = validated_params[:expected_balance]
          @checked_balance = validated_params[:checked_balance]

          @court_date = format_date(validated_params[:court_date])
          @date_of_breach = format_date(validated_params[:date_of_breach])
          @expected_balance = validated_params[:expected_balance]
          @checked_balance = validated_params[:checked_balance]

          return unless @expected_balance && @checked_balance
          @shortfall_amount = format('%.2f', calculate_shortfall_amount(@checked_balance, @expected_balance))
        end
      end
    end
  end
end
