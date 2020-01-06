module Hackney
  module IncomeCollection
    class Letter
      DEFAULT_MANDATORY_LETTER_FIELDS = %i[tenancy_ref payment_ref forename surname
                                           address_line1 address_line2
                                           address_post_code total_collectable_arrears_balance].freeze

      attr_reader :tenancy_ref, :address_line1, :address_line2,
                  :address_line3, :address_line4, :address_post_code,
                  :payment_ref, :total_collectable_arrears_balance,
                  :title, :forename, :surname, :errors, :tenant_address

      # Following the pattern used in Letter.rb
      # We don't need template_path at the moment.
      def self.build(letter_params:, template_path:)
        new(letter_params)
      end

      def initialize(params)
        validated_params = validate_mandatory_fields(
          DEFAULT_MANDATORY_LETTER_FIELDS,
          params
        )

        @tenancy_ref = validated_params[:tenancy_ref]
        @payment_ref = validated_params[:payment_ref]
        @total_collectable_arrears_balance = format('%.2f', (validated_params[:total_collectable_arrears_balance] || 0))
        @title = validated_params[:title]
        @forename = validated_params[:forename]
        @surname = validated_params[:surname]
        @tenant_address = build_tenant_address([
          validated_params[:address_line1],
          validated_params[:address_line2],
          validated_params[:address_line3],
          validated_params[:address_line4],
          validated_params[:address_post_code]
        ])
      end

      def validate_mandatory_fields(mandatory_fields, letter_params)
        @errors ||= []
        @errors.concat(
          mandatory_fields
                  .reject { |field| letter_params[field].present? }
                  .map { |mandatory_field| { name: mandatory_field.to_s, message: 'missing mandatory field' } }
        )

        letter_params
      end

      private

      def build_tenant_address(address_lines)
        address_lines = address_lines.select(&:present?)

        # Our templates are designed to have 5 lines in the address window. If the
        # tenant address doesn't have full 5 lines, we need to add enough breaks
        # to make up for that otherwise the whole letter won't pass gov notify validation
        (5 - address_lines.length).times do
          address_lines.push(' ')
        end

        address_lines.join('<br>')
      end
    end
  end
end
