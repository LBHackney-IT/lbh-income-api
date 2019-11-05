module Hackney
  module ServiceCharge
    class Letter
      DEFAULT_MANDATORY_LETTER_FIELDS = %i[payment_ref lessee_full_name
                                           correspondence_address1 correspondence_address2
                                           correspondence_postcode property_address
                                           total_collectable_arrears_balance].freeze

      attr_reader :tenancy_ref, :correspondence_address1, :correspondence_address2,
                  :correspondence_address3, :correspondence_address4, :correspondence_address5,
                  :correspondence_postcode, :property_address,
                  :payment_ref, :balance, :total_collectable_arrears_balance,
                  :lba_expiry_date, :original_lease_date, :date_of_current_purchase_assignment,
                  :original_leaseholders, :previous_letter_sent, :arrears_letter_1_date,
                  :international, :lessee_full_name, :lessee_short_name, :errors, :lba_balance, :tenure_type

      def self.build(letter_params:, template_path:)
        case template_path
        when *Hackney::ServiceCharge::Letter::BeforeAction::TEMPLATE_PATHS
          Letter::BeforeAction.new(letter_params)
        when *Hackney::ServiceCharge::Letter::LetterTwo::TEMPLATE_PATHS
          Letter::LetterTwo.new(letter_params)
        else
          new(letter_params)
        end
      end

      def initialize(params)
        validated_params = validate_mandatory_fields(
          DEFAULT_MANDATORY_LETTER_FIELDS,
          reorganise_address(params)
        )

        @tenancy_ref = validated_params[:tenancy_ref]
        @correspondence_address1 = validated_params[:correspondence_address1]
        @correspondence_address2 = validated_params[:correspondence_address2]
        @correspondence_address3 = validated_params[:correspondence_address3]
        @correspondence_address4 = validated_params[:correspondence_address4]
        @correspondence_address5 = validated_params[:correspondence_address5]
        @correspondence_postcode = validated_params[:correspondence_postcode]
        @property_address = validated_params[:property_address]
        @payment_ref = validated_params[:payment_ref]
        @balance = format('%.2f', (validated_params[:balance] || 0))
        @total_collectable_arrears_balance = format('%.2f', (validated_params[:total_collectable_arrears_balance] || 0))
        @previous_letter_sent = validated_params[:previous_letter_sent]
        @international = validated_params[:international]
        @lessee_full_name = validated_params[:lessee_full_name]
        @lessee_short_name = validated_params[:lessee_short_name]
      end

      def reorganise_address(letter_params)
        address1 = letter_params[:correspondence_address1] # corr_preamble ( the flat number/house Name)
        address2 = letter_params[:correspondence_address2] # desig + aline1
        address3 = letter_params[:correspondence_address3] # aline2
        address4 = letter_params[:correspondence_address4] # aline3 (City)
        address5 = letter_params[:correspondence_address5] # aline4 (Country)

        if address1.present?
          letter_params[:correspondence_address1] = address1
        else
          letter_params[:correspondence_address1] = address2
          address2 = ''
        end

        if address2.present?
          letter_params[:correspondence_address2] = address2
        else
          letter_params[:correspondence_address2] = address3
          address3 = ''
        end

        if address3.present?
          letter_params[:correspondence_address3] = address3
        else
          letter_params[:correspondence_address3] = address4
          address4 = ''
        end

        if address4.present?
          letter_params[:correspondence_address4] = address4
        else
          letter_params[:correspondence_address4] = address5
        end

        letter_params
      end

      def validate_mandatory_fields(mandatory_fields, letter_params)
        @errors ||= []
        @errors.concat(
          mandatory_fields
                  .reject { |field| letter_params[field].present? }
                  .map { |mandatory_field| { name: mandatory_field.to_s, message: 'missing mandatory field' } }
        )

        @errors << { name: 'address', message: 'international address' } if letter_params[:international] == true

        letter_params[:lessee_short_name] = letter_params[:lessee_full_name] unless letter_params[:lessee_short_name].present?
        letter_params
      end
    end
  end
end
