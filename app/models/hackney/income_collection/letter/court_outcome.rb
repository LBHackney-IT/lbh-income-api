module Hackney
  module IncomeCollection
    class Letter
      class CourtOutcome < Hackney::IncomeCollection::Letter
        include LetterDateHelper

        TEMPLATE_PATHS = [
          'lib/hackney/pdf/templates/income/court_outcome_letter.erb'
        ].freeze

        MANDATORY_FIELDS = %i[court_outcome court_date].freeze

        attr_reader :court_outcome, :court_date, :formal_agreement, :outright_order

        def self.build(letter_params)
          if with_terms?(letter_params)
            CourtOutcome::WithTerms.new(letter_params)
          elsif outright_order?(letter_params)
            CourtOutcome::OutrightOrder.new(letter_params)
          else
            new(letter_params)
          end
        end

        def initialize(params)
          super(params)

          validated_params = validate_mandatory_fields(MANDATORY_FIELDS, params)

          @court_outcome = human_readable_outcome(validated_params[:court_outcome])
          @court_date = format_date(validated_params[:court_date])

          @formal_agreement = self.class.with_terms?(params)
          @outright_order = self.class.outright_order?(params)
        end

        private

        def human_readable_outcome(code)
          code_mapping = {
            'AGP' => 'Adjourned generally with permission to restore',
            'AND' => 'Adjourned to next open date',
            'AAH' => 'Adjourned to another hearing date',
            'ADH' => 'Adjourned for directions hearing',
            'ADT' => 'Adjourned on terms',
            'OPF' => 'Outright possession forthwith',
            'OPD' => 'Outright possession with date',
            'SOT' => 'Suspension on terms',
            'STO' => 'Struck out',
            'WIT' => 'Withdrawn on the day',
            'SOE' => 'Stay of execution'
          }

          code_mapping[code]
        end

        class << self
          def with_terms?(params)
            params[:balance_on_court_outcome_date].present?
          end

          def outright_order?(params)
            [
              Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_FORTHWITH,
              Hackney::Tenancy::UpdatedCourtOutcomeCodes::OUTRIGHT_POSSESSION_WITH_DATE
            ].include?(params[:court_outcome])
          end
        end
      end
    end
  end
end
