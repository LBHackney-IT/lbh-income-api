module Hackney
  module IncomeCollection
    class Letter
      class CourtOutcome
        class OutrightOrder < Hackney::IncomeCollection::Letter::CourtOutcome
          include LetterDateHelper

          MANDATORY_FIELDS = %i[eviction_date].freeze

          attr_reader :eviction_date, :property_address

          def initialize(params)
            super(params)

            validated_params = validate_mandatory_fields(MANDATORY_FIELDS, params)

            @property_address = format_property_address(validated_params)

            @eviction_date = format_date(validated_params[:eviction_date])
          end

          private

          def format_property_address(validated_params)
            [validated_params[:address_line1],
             validated_params[:address_line2],
             validated_params[:address_post_code]].join(', ')
          end
        end
      end
    end
  end
end
