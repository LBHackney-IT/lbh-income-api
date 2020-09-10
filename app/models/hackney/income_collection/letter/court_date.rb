module Hackney
  module IncomeCollection
    class Letter
      class CourtDate < Hackney::IncomeCollection::Letter
        include LetterDateHelper

        TEMPLATE_PATHS = [
          'lib/hackney/pdf/templates/income/court_date_letter.erb'
        ].freeze
        MANDATORY_FIELDS = %i[court_date].freeze

        attr_reader :court_date

        def initialize(params)
          super(params)

          validated_params = validate_mandatory_fields(MANDATORY_FIELDS, params)
          @court_date = format_date(validated_params[:court_date])
        end
      end
    end
  end
end
