module Hackney
  module ServiceCharge
    class Letter
      class LetterTwo < Hackney::ServiceCharge::Letter
        TEMPLATE_PATHS = [
          'lib/hackney/pdf/templates/letter_2_in_arrears_FH.erb',
          'lib/hackney/pdf/templates/letter_2_in_arrears_LH.erb',
          'lib/hackney/pdf/templates/letter_2_in_arrears_SO.erb'
        ].freeze

        MANDATORY_FIELDS = %i[arrears_letter_1_date].freeze

        def initialize(params)
          super(params)

          @arrears_letter_1_date = fetch_previous_letter_date(params[:payment_ref])

          validate_mandatory_fields(MANDATORY_FIELDS, params.merge(arrears_letter_1_date: @arrears_letter_1_date))
        end

        private

        def fetch_previous_letter_date(payment_ref)
          sent_letter1 = Hackney::Cloud::Document
                         .where("JSON_EXTRACT(metadata, '$.template.name') Like  ?", '%Letter 1%')
                         .where("JSON_EXTRACT(metadata, '$.payment_ref') = ?", payment_ref)

          sent_letter1.any? ? sent_letter1.last.updated_at.strftime('%d %B %Y') : ''
        end
      end
    end
  end
end
